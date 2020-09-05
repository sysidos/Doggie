//
//  SVGConvolveKernel.metal
//
//  The MIT License
//  Copyright (c) 2015 - 2020 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#include <metal_stdlib>
using namespace metal;

constexpr sampler svg_convolve_duplicate_sampler (coord::pixel, address::clamp_to_edge, filter::linear);
constexpr sampler svg_convolve_wrap_sampler (address::repeat, filter::linear);
constexpr sampler svg_convolve_none_sampler (coord::pixel, address::clamp_to_zero, filter::linear);

constant int ORDER_X [[function_constant(0)]];
constant int ORDER_Y [[function_constant(1)]];

half3 svg_convolve_color_normalized(texture2d<half, access::sample> input, sampler input_sampler, constant float *matrix, float2 unit, float2 coord) {
    
    const int input_width = input.get_width();
    const int input_height = input.get_height();
    
    half3 sum = 0;
    
    for (int j = 0; j < ORDER_Y; ++j) {
        for (int i = 0; i < ORDER_X; ++i) {
            
            const int kx = ORDER_X - i - 1;
            const int ky = ORDER_Y - j - 1;
            
            const float coord_x = coord.x + (float)i * unit.x;
            const float coord_y = coord.y + (float)j * unit.y;
            
            const half4 sample = input.sample(input_sampler, float2(coord_x / (float)input_width, coord_y / (float)input_height));
            
            if (sample.w != 0) {
                sum += sample.xyz / sample.w * matrix[ky * ORDER_X + kx];
            } else {
                sum += sample.xyz * matrix[ky * ORDER_X + kx];
            }
        }
    }
    
    return sum;
}

half4 svg_convolve_normalized(texture2d<half, access::sample> input, sampler input_sampler, constant float *matrix, float2 unit, float2 coord) {
    
    const int input_width = input.get_width();
    const int input_height = input.get_height();
    
    half4 sum = 0;
    
    for (int j = 0; j < ORDER_Y; ++j) {
        for (int i = 0; i < ORDER_X; ++i) {
            
            const int kx = ORDER_X - i - 1;
            const int ky = ORDER_Y - j - 1;
            
            const float coord_x = coord.x + (float)i * unit.x;
            const float coord_y = coord.y + (float)j * unit.y;
            
            const half4 sample = input.sample(input_sampler, float2(coord_x / (float)input_width, coord_y / (float)input_height));
            
            sum += sample * matrix[ky * ORDER_X + kx];
        }
    }
    
    return sum;
}

half3 svg_convolve_color(texture2d<half, access::sample> input, sampler input_sampler, constant float *matrix, float2 unit, float2 coord) {
    
    half3 sum = 0;
    
    for (int j = 0; j < ORDER_Y; ++j) {
        for (int i = 0; i < ORDER_X; ++i) {
            
            const int kx = ORDER_X - i - 1;
            const int ky = ORDER_Y - j - 1;
            
            const float offset_x = (float)i * unit.x;
            const float offset_y = (float)j * unit.y;
            
            const half4 sample = input.sample(input_sampler, coord + float2(offset_x, offset_y));
            
            if (sample.w != 0) {
                sum += sample.xyz / sample.w * matrix[ky * ORDER_X + kx];
            } else {
                sum += sample.xyz * matrix[ky * ORDER_X + kx];
            }
        }
    }
    
    return sum;
}

half4 svg_convolve(texture2d<half, access::sample> input, sampler input_sampler, constant float *matrix, float2 unit, float2 coord) {
    
    half4 sum = 0;
    
    for (int j = 0; j < ORDER_Y; ++j) {
        for (int i = 0; i < ORDER_X; ++i) {
            
            const int kx = ORDER_X - i - 1;
            const int ky = ORDER_Y - j - 1;
            
            const float offset_x = (float)i * unit.x;
            const float offset_y = (float)j * unit.y;
            
            const half4 sample = input.sample(input_sampler, coord + float2(offset_x, offset_y));
            
            sum += sample * matrix[ky * ORDER_X + kx];
        }
    }
    
    return sum;
}

kernel void svg_convolve_duplicate(texture2d<half, access::sample> input [[texture(0)]],
                                   texture2d<half, access::write> output [[texture(1)]],
                                   constant float *matrix [[buffer(2)]],
                                   constant float &bias [[buffer(3)]],
                                   constant packed_float2 &offset [[buffer(4)]],
                                   constant packed_float2 &unit [[buffer(5)]],
                                   uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) { return; }
    
    half4 sum = svg_convolve(input, svg_convolve_duplicate_sampler, matrix, (float2)unit, (float2)gid);
    
    sum.w += bias;
    sum.xyz += bias * sum.w;
    
    output.write(sum, gid);
}

kernel void svg_convolve_wrap(texture2d<half, access::sample> input [[texture(0)]],
                              texture2d<half, access::write> output [[texture(1)]],
                              constant float *matrix [[buffer(2)]],
                              constant float &bias [[buffer(3)]],
                              constant packed_float2 &offset [[buffer(4)]],
                              constant packed_float2 &unit [[buffer(5)]],
                              uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) { return; }
    
    half4 sum = svg_convolve_normalized(input, svg_convolve_wrap_sampler, matrix, (float2)unit, (float2)gid);
    
    sum.w += bias;
    sum.xyz += bias * sum.w;
    
    output.write(sum, gid);
}

kernel void svg_convolve_none(texture2d<half, access::sample> input [[texture(0)]],
                              texture2d<half, access::write> output [[texture(1)]],
                              constant float *matrix [[buffer(2)]],
                              constant float &bias [[buffer(3)]],
                              constant packed_float2 &offset [[buffer(4)]],
                              constant packed_float2 &unit [[buffer(5)]],
                              uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) { return; }
    
    half4 sum = svg_convolve(input, svg_convolve_none_sampler, matrix, (float2)unit, (float2)gid);
    
    sum.w += bias;
    sum.xyz += bias * sum.w;
    
    output.write(sum, gid);
}

kernel void svg_convolve_duplicate_preserve_alpha(texture2d<half, access::sample> input [[texture(0)]],
                                                  texture2d<half, access::write> output [[texture(1)]],
                                                  constant float *matrix [[buffer(2)]],
                                                  constant float &bias [[buffer(3)]],
                                                  constant packed_float2 &offset [[buffer(4)]],
                                                  constant packed_float2 &unit [[buffer(5)]],
                                                  uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) { return; }
    
    const half _alpha = input.sample(svg_convolve_none_sampler, (float2)gid + offset).w;
    
    const half3 sum = svg_convolve_color(input, svg_convolve_duplicate_sampler, matrix, (float2)unit, (float2)gid);
    
    output.write(half4((sum + bias) * _alpha, _alpha), gid);
}

kernel void svg_convolve_wrap_preserve_alpha(texture2d<half, access::sample> input [[texture(0)]],
                                             texture2d<half, access::write> output [[texture(1)]],
                                             constant float *matrix [[buffer(2)]],
                                             constant float &bias [[buffer(3)]],
                                             constant packed_float2 &offset [[buffer(4)]],
                                             constant packed_float2 &unit [[buffer(5)]],
                                             uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) { return; }
    
    const half _alpha = input.sample(svg_convolve_none_sampler, (float2)gid + offset).w;
    
    const half3 sum = svg_convolve_color_normalized(input, svg_convolve_wrap_sampler, matrix, (float2)unit, (float2)gid);
    
    output.write(half4((sum + bias) * _alpha, _alpha), gid);
}

kernel void svg_convolve_none_preserve_alpha(texture2d<half, access::sample> input [[texture(0)]],
                                             texture2d<half, access::write> output [[texture(1)]],
                                             constant float *matrix [[buffer(2)]],
                                             constant float &bias [[buffer(3)]],
                                             constant packed_float2 &offset [[buffer(4)]],
                                             constant packed_float2 &unit [[buffer(5)]],
                                             uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) { return; }
    
    const half _alpha = input.sample(svg_convolve_none_sampler, (float2)gid + offset).w;
    
    const half3 sum = svg_convolve_color(input, svg_convolve_none_sampler, matrix, (float2)unit, (float2)gid);
    
    output.write(half4((sum + bias) * _alpha, _alpha), gid);
}
