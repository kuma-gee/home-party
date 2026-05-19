shader_type spatial;
render_mode cull_disabled;

uniform vec3 Main_Color : source_color = vec3(1.0);
uniform vec3 Effect_Color : source_color = vec3(0.3, 0.3, 1.0);

uniform int Octave_Count : hint_range(1, 20) = 10;
uniform float Amp_Start = 0.5;
uniform float Amp_Coeff = 0.5;
uniform float Freq_Coeff = 2.0;
uniform float Speed = 3.0;

uniform float Y_Size = 4.0;
uniform float X_Size = 1.0;
// Controls visual thickness of the lightning. Values >1 make it thicker, <1 make it thinner.
uniform float Thickness : hint_range(0.01, 10.0) = 1.0;

// Rotation of the whole lightning pattern in degrees. Use positive values to rotate
// counter-clockwise. This rotates the UVs after centering and scaling so the
// lightning can be oriented arbitrarily.
uniform float Rotation_Degrees : hint_range(-180.0, 180.0) = 0.0;

uniform float Emission_Power = 2.0;
uniform sampler2D Power_Texture : source_color;

float Hash12(vec2 UV_)
{
	return fract(cos(mod(dot(UV_, vec2(13.9898, 8.141)), 3.14)) * 43758.5453);
}

vec2 Hash22(vec2 UV_)
{
	UV_ = vec2(dot(UV_, vec2(127.1,311.7)),
	dot(UV_, vec2(269.5,183.3)));
	return 2.0 * fract(sin(UV_) * 43758.5453123);
}

float Noise(vec2 UV_)
{
	vec2 IUV = floor(UV_);
	vec2 FUV = fract(UV_);
	vec2 Blur = smoothstep(0.0, 1.0, FUV);

	float A = dot(Hash22(IUV + vec2(0.0,0.0)), FUV - vec2(0.0,0.0));
	float B = dot(Hash22(IUV + vec2(1.0,0.0)), FUV - vec2(1.0,0.0));
	float C = dot(Hash22(IUV + vec2(0.0,1.0)), FUV - vec2(0.0,1.0));
	float D = dot(Hash22(IUV + vec2(1.0,1.0)), FUV - vec2(1.0,1.0));

	float Mix_X1 = mix(A, B, Blur.x);
	float Mix_X2 = mix(C, D, Blur.x);

	return mix(Mix_X1, Mix_X2, Blur.y) + 0.5;
}

float FBM(vec2 UV_)
{
	float Value = 0.0;
	float Amplitude = Amp_Start;

	for (int Index = 0; Index < Octave_Count; Index++)
	{
		Value += Amplitude * Noise(UV_);
		UV_ *= Freq_Coeff;
		Amplitude *= Amp_Coeff;
	}

	return Value;
}

uniform bool y_billboard = false; // Enables Y-Billboarding when true
uniform bool x_billboard = false; // Enables X-Billboarding when true
uniform sampler2D gradient;

void vertex() {
    // You can comment out this function if you don't need billboarding
    // Priority: x_billboard > y_billboard > none
    if (x_billboard == true) {
        // Build a modelview matrix that keeps the X axis fixed (world X = (1,0,0))
        // so the quad can rotate to face the camera around the X axis.
        vec3 cam_forward = INV_VIEW_MATRIX[2].xyz;
        vec3 X_fixed = vec3(1.0, 0.0, 0.0);
        vec3 Y_axis = normalize(cross(cam_forward, X_fixed));
        vec3 Z_axis = normalize(cross(X_fixed, Y_axis));
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(X_fixed, 0.0), vec4(Y_axis, 0.0), vec4(Z_axis, 0.0), MODEL_MATRIX[3]);
    }
    else if (y_billboard == true) {
        // Keep Y axis fixed (world up = (0,1,0)) - existing behaviour
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
    }
    else {
        // Default: use the view-aligned inverse rows so the mesh behaves normally
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    }
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment()
{
	float Power_Value = texture(Power_Texture, UV).r;
	float gradient_alpha = texture(gradient, UV).r;

    vec2 Modified_UV = 2.0 * UV - 1.0;
    // Apply non-uniform scaling first so rotation respects aspect
    Modified_UV.y *= Y_Size;
    Modified_UV.x *= X_Size;

    // Rotate the pattern by Rotation_Degrees around the UV center (0,0).
    // Convert degrees to radians for trig functions.
    float _angle = radians(Rotation_Degrees);
    float _c = cos(_angle);
    float _s = sin(_angle);
    Modified_UV = vec2(Modified_UV.x * _c - Modified_UV.y * _s,
                       Modified_UV.x * _s + Modified_UV.y * _c);

	Modified_UV.x -= Amp_Start;
	Modified_UV += FBM(Modified_UV + TIME * Speed);
	Modified_UV.x += 0.5 - Amp_Coeff;

    // Scale distance by Thickness so larger values produce a thicker-looking bolt.
    float Dist = abs(Modified_UV.x) / max(0.0001, Thickness);

	vec3 Final_Color = Effect_Color * mix(0.0, 0.05, Hash12(vec2(TIME))) / Dist;

	ALBEDO = Final_Color * Main_Color;
	EMISSION = ALBEDO * Emission_Power;
	ALPHA = Final_Color.r * gradient_alpha;
}
