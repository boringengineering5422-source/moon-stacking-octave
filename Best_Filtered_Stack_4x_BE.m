clear; close all; clc;

try
    pkg load image;
catch
    fprintf('Note: Image package could not be loaded.\n');
end

folder = '.';
files = dir(fullfile(folder, 'frame_*.png'));
num_frames = length(files);

fprintf('=== Moon Stacking - Fixed 88 + Lucky Imaging ===\n');
fprintf('Frames found: %d\n', num_frames);

% ============================================================
% HELPER FUNCTIONS
% ============================================================

function gray = my_rgb2gray(rgb)
    % Convert RGB to grayscale
    if size(rgb, 3) == 3
        gray = 0.2989 * double(rgb(:,:,1)) + ...
               0.5870 * double(rgb(:,:,2)) + ...
               0.1140 * double(rgb(:,:,3));
    else
        gray = double(rgb);
    end
end

function [shift_y, shift_x, max_val, subpix_y, subpix_x] = phase_correlate(ref, mov, crop)
    % Phase correlation for image alignment with sub-pixel accuracy
    [h, w] = size(ref);
    r = ref(crop+1:h-crop, crop+1:w-crop);
    m = mov(crop+1:h-crop, crop+1:w-crop);
    [ch, cw] = size(r);

    win = hanning(ch) * hanning(cw)';
    r = r .* win;
    m = m .* win;

    r = r - mean(r(:));
    m = m - mean(m(:));

    R = fft2(r);
    M = fft2(m);
    cross = R .* conj(M);
    magnitude = abs(cross);
    magnitude(magnitude < 1e-10) = 1e-10;
    normalized = cross ./ magnitude;

    c = real(ifft2(normalized));
    [~, idx] = max(c(:));
    [py, px] = ind2sub(size(c), idx);

    [ch, cw] = size(c);
    shift_y = py - 1;
    shift_x = px - 1;

    if shift_y > ch/2, shift_y = shift_y - ch; end
    if shift_x > cw/2, shift_x = shift_x - cw; end

    max_val = c(py, px);

    subpix_y = 0;
    subpix_x = 0;

    % Sub-pixel refinement
    if py > 1 && py < ch && px > 1 && px < cw
        v_up = c(py-1, px);
        v_mid = c(py, px);
        v_down = c(py+1, px);
        denom_y = v_up - 2*v_mid + v_down;
        if abs(denom_y) > 1e-10
            subpix_y = 0.5 * (v_up - v_down) / denom_y;
        end

        v_left = c(py, px-1);
        v_right = c(py, px+1);
        denom_x = v_left - 2*v_mid + v_right;
        if abs(denom_x) > 1e-10
            subpix_x = 0.5 * (v_left - v_right) / denom_x;
        end
    end

    subpix_y = max(-0.5, min(0.5, subpix_y));
    subpix_x = max(-0.5, min(0.5, subpix_x));
end

function sharpness = calculate_sharpness(img)
    % Calculate sharpness using Laplacian variance (Lucky Imaging)
    laplace_kernel = [0 1 0; 1 -4 1; 0 1 0];
    laplacian = conv2(double(img), laplace_kernel, 'same');
    sharpness = std(laplacian(:))^2;
end

function out = my_translate_subpixel(img, dx, dy)
    % Translate image with sub-pixel accuracy using bicubic interpolation
    [h, w] = size(img);
    [X, Y] = meshgrid(1:w, 1:h);
    X_new = X + dx;
    Y_new = Y + dy;
    out = interp2(double(img), X_new, Y_new, 'cubic', 0);
    out = max(0, min(255, out));
end

function out = my_unsharp_mask(img, amount, radius)
    % Apply unsharp masking
    sigma = radius / 2;
    ksize = max(3, 2*ceil(3*sigma) + 1);
    if mod(ksize, 2) == 0
        ksize = ksize + 1;
    end
    [X, Y] = meshgrid(-(ksize-1)/2:(ksize-1)/2);
    kernel = exp(-(X.^2 + Y.^2) / (2*sigma^2));
    kernel = kernel / sum(kernel(:));
    blurred = conv2(img, kernel, 'same');
    out = img + amount * (img - blurred);
    out = max(0, min(255, out));
end

function out = my_contrast_stretch(img, low_pct, high_pct)
    % Contrast stretch using percentile clipping
    sorted = sort(img(:));
    n = length(sorted);
    lo_idx = max(1, floor(n * low_pct));
    hi_idx = min(n, ceil(n * high_pct));
    lo = sorted(lo_idx);
    hi = sorted(hi_idx);
    if hi == lo
        out = img;
    else
        out = (double(img) - lo) / (hi - lo) * 255;
    end
    out = max(0, min(255, out));
end

function out = my_resize_bicubic_4x(img)
    % Resize image to 4x size using bicubic interpolation + sharpening
    [h, w] = size(img);
    new_h = h * 4;
    new_w = w * 4;
    img_d = double(img);
    [X, Y] = meshgrid(linspace(1, w, new_w), linspace(1, h, new_h));
    out = interp2(img_d, X, Y, 'cubic');
    out = my_unsharp_mask(out, 0.5, 1.2);
    out = max(0, min(255, out));
end

% ============================================================
% MAIN PROGRAM
% ============================================================

ref_idx = round(num_frames / 2);
ref_rgb = imread(fullfile(folder, files(ref_idx).name));
ref = my_rgb2gray(ref_rgb);

[h, w] = size(ref);
stacked = zeros(h, w);
used = 0;

total_shifts_y = zeros(num_frames, 1);
total_shifts_x = zeros(num_frames, 1);
sharpness_scores = zeros(num_frames, 1);

crop = 50;

disp('Running alignment & sharpness check...');

for i = 1:num_frames
    img_rgb = imread(fullfile(folder, files(i).name));
    img = my_rgb2gray(img_rgb);

    % 1. Alignment using phase correlation
    [dy, dx, conf, subpix_y, subpix_x] = phase_correlate(ref, img, crop);

    total_dy = dy + subpix_y;
    total_dx = dx + subpix_x;

    total_shifts_y(i) = total_dy;
    total_shifts_x(i) = total_dx;

    % 2. Calculate sharpness for Lucky Imaging
    sharpness_scores(i) = calculate_sharpness(img);

    % 3. Stack only sharp and well-aligned frames
    if conf > 0.3
        shifted = my_translate_subpixel(img, total_dx, total_dy);
        stacked = stacked + shifted;
        used = used + 1;
    end

    if mod(i, 40) == 0
        fprintf('Frame %d / %d (used: %d)\n', i, num_frames, used);
    end
end

if used == 0
    error('No frames were used! The confidence threshold is too high.');
end

% Create stacked image
result = uint8(stacked / used);

% Apply sharpening and contrast enhancement
result_sharp = my_unsharp_mask(double(result), 3.5, 3.0);
result_final = uint8(my_contrast_stretch(result_sharp, 0.001, 0.999));

% Save final images
imwrite(result_final, 'Moon_Stack_Final_88_Fixed22.png');
fprintf('Saved: Moon_Stack_Final_88_Fixed22.png\n');

% Create 4x upscaled version
result_4x = my_resize_bicubic_4x(double(result_final));
imwrite(uint8(result_4x), 'Moon_Stack_Final_4x_88_Fixed22.png');
fprintf('Saved: Moon_Stack_Final_4x_88_Fixed22.png\n');

fprintf('\n=== Finished! ===\n');
fprintf('Frames used: %d of %d\n', used, num_frames);
fprintf('Average shift: Y=%.3f, X=%.3f pixels\n', mean(total_shifts_y), mean(total_shifts_x));
fprintf('Std deviation: Y=%.3f, X=%.3f pixels\n', std(total_shifts_y), std(total_shifts_x));

% Optional: Plot shifts
figure;
subplot(2,1,1);
plot(total_shifts_y, 'b.');
title('Y-Shift per Frame');
xlabel('Frame');
ylabel('Pixels');

subplot(2,1,2);
plot(total_shifts_x, 'r.');
title('X-Shift per Frame');
xlabel('Frame');
ylabel('Pixels');
