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
    float wobbleX = sin(uv.y * 10.0 + time * 2.0) * wobble_strength;
    float wobbleY = cos(uv.x * 10.0 + time * 1.5) * wobble_strength;
    uv += vec2(wobbleX, wobbleY);

    // Apply chromatic aberration by offsetting the RGB channels slightly
    float aberration = sin(time * 3.0) * aberration_strength;
    vec2 redOffset = uv + vec2(aberration, 0.0);
    vec2 greenOffset = uv + vec2(-aberration, aberration);
    vec2 blueOffset = uv + vec2(0.0, -aberration);

    // Sample the texture with offsets
    vec3 red = texture(baseMap, redOffset).rgb;
    vec3 green = texture(baseMap, greenOffset).rgb;
    vec3 blue = texture(baseMap, blueOffset).rgb;

    // Combine the channels
    vec3 color = vec3(red.r, green.g, blue.b);

    // Output the final color
    gl_FragColor = vec4(color, 1.0);
}
