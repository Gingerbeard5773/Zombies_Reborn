//drunk shader
//gingerbeard got this from chatgpt LOL

uniform sampler2D baseMap;       // Texture to apply the effect to
uniform float time;              // Time variable for animation
uniform float wobble_strength;   // Strength of wobble distortion
uniform float aberration_strength; // Strength of chromatic aberration

void main()
{
    vec2 uv = gl_TexCoord[0].xy; // Original texture coordinates

    // Wobble distortion using sine wave
    float wobble_x = sin(uv.y * 10.0 + time * 2.0) * wobble_strength;
    float wobble_y = cos(uv.x * 10.0 + time * 1.5) * wobble_strength;
    uv += vec2(wobble_x, wobble_y);

    // Apply chromatic aberration by offsetting the RGB channels slightly
    float aberration = sin(time * 3.0) * aberration_strength;
    vec2 red_offset = uv + vec2(aberration, 0.0);
    vec2 green_offset = uv + vec2(-aberration, aberration);
    vec2 blue_offset = uv + vec2(0.0, -aberration);

    // Sample the texture with offsets
    vec3 red = texture2D(baseMap, red_offset).rgb;
    vec3 green = texture2D(baseMap, green_offset).rgb;
    vec3 blue = texture2D(baseMap, blue_offset).rgb;

    // Combine the channels
    vec3 color = vec3(red.r, green.g, blue.b);

    // Output the final color
    gl_FragColor = vec4(color, 1.0);
}
