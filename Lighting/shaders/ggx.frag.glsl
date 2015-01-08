// --------------------------------------------
// GGX Shader
// --------------------------------------------
// Optimization from optimized-ggx.hlsl by John Hable

uniform float aK;
uniform float dK;
uniform float sK;

uniform float Exposure;
uniform vec3 BgColor;
uniform vec2 Resolution;
uniform float Fresnel;

varying vec3 aC;
varying vec3 dC;
varying vec3 sC;

varying vec3 N;
varying vec3 P;
varying vec3 V;
varying vec3 L;

varying float I;
varying float Roughness;

vec3 Uncharted2Tonemap(vec3 x)
{
  float A = 0.15;
  float B = 0.50;
  float C = 0.10;
  float D = 0.20;
  float E = 0.02;
  float F = 0.30;

  return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float G1V(float dotNV, float k)
{
	return 1.0/(dotNV*(1.0-k)+k);
}

float LightingFuncGGX(vec3 L, vec3 V, vec3 N, float roughness, float F0)
{
	float alpha = roughness*roughness;

	vec3 H = normalize(V+L);

	float dotNL = clamp(dot(N,L), 0., 1.);
	float dotNV = clamp(dot(N,V), 0., 1.);
	float dotNH = clamp(dot(N,H), 0., 1.);
	float dotLH = clamp(dot(L,H), 0., 1.);

	float F, D, vis;

	// D
	float alphaSqr = alpha*alpha;
	float pi = 3.14159;
	float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0;
	D = alphaSqr/(pi * denom * denom);

	// F
	float dotLH5 = pow(1.0-dotLH,5.);
	F = F0 + (1.0-F0)*(dotLH5);

	// V
	float k = alpha/2.0;
	vis = G1V(dotNL,k)*G1V(dotNV,k);

	float specular = dotNL * D * F * vis;
	return specular;
}

float LightingFuncGGX_OPT1(vec3 L, vec3 V, vec3 N, float roughness, float F0)
{
	float alpha = roughness*roughness;

	vec3 H = normalize(V+L);

	float dotNL = clamp(dot(N,L), 0., 1.);
	float dotNH = clamp(dot(N,H), 0., 1.);
	float dotLH = clamp(dot(L,H), 0., 1.);

	float F, D, vis;

	// D
	float alphaSqr = alpha*alpha;
	float pi = 3.14159;
	float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0;
	D = alphaSqr/(pi * denom * denom);

	// F
	float dotLH5 = pow(1.0-dotLH,5.);
	F = F0 + (1.0-F0)*(dotLH5);

	// V
	float k = alpha/2.0;
	vis = G1V(dotLH,k)*G1V(dotLH,k);

	float specular = dotNL * D * F * vis;
	return specular;
}

void main()
{ 
  vec3 l = normalize(L);
  vec3 n = normalize(N);
  vec3 v = normalize(V);
  // vec3 h = normalize(l+v);

  float diffuse = max(0., dot(l,n));
  float specular = LightingFuncGGX_OPT1(l, v, n, Roughness, Fresnel);
    
  gl_FragColor = vec4(aC * aK +
                      I * (dC * diffuse * dK +
                      sC * specular * sK), 1);

  // Tone mapping
  gl_FragColor.rgb = Uncharted2Tonemap(gl_FragColor.rgb * Exposure) / Uncharted2Tonemap(vec3(1));

  // Gamma correction
  gl_FragColor.rgb = pow(gl_FragColor.rgb, vec3(1.0 / 2.2));
}
