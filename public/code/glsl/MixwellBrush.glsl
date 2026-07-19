// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Doug L. James and Ethan James

///////////////////////////////////////////////////////////////////////
///  Mixwell-Brush Library Functions /// @author Doug L James, 2026 ///
///////////////////////////////////////////////////////////////////////

const float PI     = 3.14159265358979323846; // π

// Cutoff distance (as multiple of tine radius) beyond which rdSegment is zero.
const float RDSEGMENT_MASK_R_FACTOR = 10.0;

/*** [BEGIN] SDF FUNCTIONS *******************************************/

float sdSegment(vec2 p, vec2 a, vec2 b) {
  vec2  pa = p - a;
  vec2  ba = b - a;
  float h  = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0);
  return length(pa - ba*h);
}

/*** [END] SDF FUNCTIONS *******************************************/

/*****************************************************************************/
/*** [BEGIN] COLOR & TEST IMAGES                       ***********************/
/*****************************************************************************/

// Paint texture
vec3 paintChocolate(vec2 q) {
  float theta = 0.3;
  float c     = cos(theta);
  float s     = sin(theta);
  vec2  p     = vec2(c*q.x - s*q.y, s*q.x + c*q.y);
  float k0    = 45.0;
  float k1    = 29.0;
  float phi0  = 3.0;
  float phi1  = 2.0;
  vec3  col0  = vec3(0.6862745098, 0.4,          0.1490196078); // rgb(175, 102,  38);
  vec3  col1  = vec3(0.6901960784, 0.9411764706, 0.9921568627); // rgb(176, 240, 253);
  vec3  colChocolate = vec3(0.1490196078, 0.0862745098, 0.0901960784); // rgb(38,22,23);
  float splat0 = smoothstep(0.5, 0.64, sin(k0*p.x*(1.0 - 0.153*p.x) + phi0)*sin(k0*p.y*(1.0 + 0.6*p.x) + phi0)*(1.0 - 0.2*sin(12.0*p.x*p.x)));
  float splat1 = smoothstep(0.5, 0.64, sin(k1*p.x*(1.0 + 0.230*p.x) + phi1)*cos(k1*p.y*(1.0 - 0.1*p.x) + phi1)*(1.0 - 0.2*sin(12.0*p.x*p.y)));
  vec3  col = mix(colChocolate + splat0*col0, col1, splat1);

  return col;
}

vec3 paintTestSquare(vec2 q) {
  return vec3(1.0) * smoothstep(0.1, 0.11, q.x) * smoothstep(0.2, 0.19, q.x) *
         smoothstep(0.1, 0.11, q.y) * smoothstep(0.2, 0.19, q.y);
}

vec3 paintStripes(vec2 q) {
  return pow(smoothstep(0.0, 1.0, fract(6.0*q.y + sin(33.0*q.x))), 3.0) * vec3(1.0);
}

// Adapted from https://webgl-operate.org/examples/canvassize-example.html
vec3 paintTestImage(vec2 fragCoord) {
  const float CELL_WIDTH = 1.0/32.0;

  vec3 x3 = vec3(fragCoord.x) + vec3(0.0, 1.0, 2.0);
  vec3 y3 = vec3(fragCoord.y) + vec3(0.0, 1.0, 2.0);

  vec3 x = step(mod(x3, vec3(3.0)), vec3(1.0));
  vec3 y = step(mod(y3, vec3(3.0)), vec3(1.0));

  float cell = step(mod(fragCoord.x*CELL_WIDTH + floor(fragCoord.y*CELL_WIDTH), 2.0), 1.0);

  return mix(x, y, cell);
}

vec3 paintCheckerboard(vec2 q, float h) {
  ivec2 cell = ivec2(floor(q/h));
  return vec3(float((cell.x + cell.y) & 1));
}

vec3 splatBlobRows(vec2 p, vec3 colBG, vec3 colBlob, float HX, float HY, float dY, float blobRadius, bool isOddRow) {
  float Yoffset = isOddRow ? 0.5*HY : 0.;

  // SNAP p to closest horizontal row:
  float ySnap = Yoffset + round((p.y - Yoffset)/HY)*HY; // y of closest row
  p.y -= ySnap;
  p.x -= sin(437.5453*ySnap)*437.5453; // SHIFT X per ROW

  // STRING OF BLOBS ON y=0 AXIS:
  float F = 1239. + ySnap; // nat freq for variation

  // Mission: Find our blob i:
  float x0 = HX*floor(p.x/HX);
  float x1 = x0 + HX; // ceil
  vec2  p0 = vec2(x0, dY*sin(F*x0));
  vec2  p1 = vec2(x1, dY*sin(F*x1));
  float D0 = dot(p-p0, p-p0);
  float D1 = dot(p-p1, p-p1);
  float iC = (D0 < D1) ? round(x0/HX) : round(x1/HX);

  // Render blob: It takes three blobs to raise a blob:
  float xC = iC*HX; // center (i)
  float xL = xC - HX; // left   (i-1)
  float xR = xC + HX; // right  (i+1)
  float yC = dY*sin(F*xC); // ignore Yoffset here
  float yL = dY*sin(F*xL);
  float yR = dY*sin(F*xR);
  vec2  pC = vec2(xC, yC);
  vec2  pL = vec2(xL, yL);
  vec2  pR = vec2(xR, yR);
  float e2 = 0.00001*HX*HX;
  float DC = dot(p-pC, p-pC) + e2;
  float DL = dot(p-pL, p-pL) + e2;
  float DR = dot(p-pR, p-pR) + e2;
  float f  = 1./DC - 1./DL - 1./DR;

  // Implicit blob size hint:
  f -= 1./(blobRadius*blobRadius);

  float reg = smoothstep(HX, 2.*HX, max(0., f));
  return mix(colBG, colBlob, reg);
}

const vec3 paletteBluePurple[6] = vec3[6](
    vec3(  8.,   8., 140.)/255.0,
    vec3( 31.,  17., 112.)/255.0,
    vec3( 17., 151., 247.)/255.0,
    vec3( 97.,  25., 191.)/255.0,
    vec3(235., 251., 252.)/255.0,
    vec3(255., 212., 235.)/255.0
);
//------------------------------------------------------------------------------
// Palette 1: Coolors example (brown blue)
// 1a344d,1e8eb6,fc9843,5a1800,f7f5f6
//------------------------------------------------------------------------------
const vec3 paletteCoolors1[6] = vec3[6](
    vec3(0.1019608, 0.2039216, 0.3019608),
    vec3(0.3529412, 0.09411765, 0.0),
    vec3(0.1176471, 0.5568628, 0.7137255),
    vec3(0.9882353, 0.5960785, 0.2627451),
    vec3(0.9686275, 0.9607843, 0.9647059),
    vec3(0.9686275, 0.9607843, 0.9647059)
);

//------------------------------------------------------------------------------
// Palette: fb6107,f3de2c,7cb518,5c8001,fbb02d
// Names: Blaze Orange, Golden Glow, Lime Moss, Forest Moss, Sunflower Gold
//------------------------------------------------------------------------------
const vec3 paletteGoldenMeadow[6] = vec3[6](
    vec3(0.9843137, 0.3803922, 0.0274510), // fb6107
    vec3(0.3607843, 0.5019608, 0.0039216), // 5c8001
    vec3(0.9843137, 0.6901961, 0.1764706), // fbb02d
    vec3(0.4862745, 0.7098039, 0.0941176), // 7cb518
    vec3(0.9529412, 0.8705882, 0.1725490), // f3de2c
    vec3(0.9529412, 0.8705882, 0.1725490)  // f3de2c
);

vec3 paintBlobsWithPalette(vec2 p, vec3 palette[6]) {
  float HX = 0.25; // X CELL SIZE
  float HY = 1.; // ROW SPACING
  float dY = HX/10.; // Y POSITION VARIATION
  float blobRadius = 2.*HX; // BLOB SIZE HINT FOR SMALLER BLOBS

  vec3 col = vec3(0.); // Background
  col = splatBlobRows(p, col, palette[0], HX, HY, dY, 2.*HX, false);
  col = splatBlobRows(p, col, palette[1], HX, HY, dY, 2.*HX, true);
  col = splatBlobRows(p, col, palette[2], HX, HY, dY, HX/2., false);
  col = splatBlobRows(p, col, palette[3], HX, HY, dY, HX/3., true);
  col = splatBlobRows(p, col, palette[4], HX, HY, dY, HX/6., false);
  col = splatBlobRows(p, col, palette[5], HX, HY, dY, HX/7., true);

  return col;
}

vec3 paintBlobs(vec2 p) {
  return paintBlobsWithPalette(p, paletteGoldenMeadow);
}

/*****************************************************************************/
/*** [ END ] COLOR & TEST IMAGES                       ***********************/
/*****************************************************************************/

/*** [BEGIN] UTILITIES *******************************************/

// Returns (-y,x) given v=(x,y).
vec2 rot90(vec2 v) {
  return vec2(-v.y, v.x);
}

// Simple pseudorandom float-to-float[0,1] hash.
float iqhash(float n) {
  return fract(sin(n)*43758.5453);
}

/*** [END] UTILITIES *******************************************/


/*****************************************************************************/
/*** [BEGIN] REVERSE-DRIFT FIELD (RDF) IMPLEMENTATIONS                      **/
/*****************************************************************************/

// Line RDF: Matched series approximation to 1D drift.
// Input: height above flow line, and cylinder radius, r.
float rdLine1DS(float height, float r) {
  float y = height / r;
  float dx = 0.; // drift = 5.f * r / (0.2f + pow(eta, 3.f));

  float eps = 0.002;
  y = sqrt(y*y + eps*eps); // y_eps

  if (y > 6.50416858646776) {
    float h  = 1./y;
    float h2 = h*h;
    float h3 = h*h2;
    float poly = ((((6615.*h2 - 1960.)*h2 + 600.)*h2 - 192.)*h2 + 64.);
    dx = -(PI/256.)*h3*poly;
  } else if (y > 0.8220844420096408) {
    float dy  = y - 2.3;
    float num = (((((-1.01973e-7*dy + 1.77539e-6)*dy - 0.0068946)*dy - 0.043355)*dy - 0.0937878)*dy - 0.0413839);
    float den = ((((((0.00875686*dy + 0.115772)*dy + 0.665761)*dy + 2.08615)*dy + 3.66495)*dy + 3.26035)*dy + 1.0);
    dx = num/den;
  } else {
    float z = y*y;
    float A = ((((0.00015811568*z - 0.00096477622)*z + 0.0076619254)*z - 0.16369764)*z - 0.039720771);
    float B = ((((-0.00018775463*z + 0.0010681152)*z - 0.0073242188)*z + 0.09375)*z + 0.5);
    dx = A + B*log(y);
  }

  return 2.0*r*dx; // UNDO UNIT-RADIUS XFORM & *2 for full drift.
}

// Returns rdLine1DS series implementation of 1D drift. Provided for "backwards convenience."
float drift1D(float height, float r) {
  return rdLine1DS(height, r);
}

// RDF at p for a circle(r) passing along an infinite line in (dir)ection passing through origin.
vec2 rdLine(vec2 p, float r, vec2 dir) {
  dir = normalize(dir);
  vec2  n = rot90(dir); // vec2(-dir.y, +dir.x);
  float height = dot(p, n);
  vec2  rdf = rdLine1DS(height, r) * dir;
  return rdf;
}

// Min distance from y to a tine of a comb with pitch hy, rooted at the origin.
float minCombDist(float y, float hy) {
  return hy * abs(fract(y/hy - 0.5) - 0.5);
}

// RDF for Nonpareil pattern.
// Inputs:
//   p            : Evaluation point.
//   r            : Tine radius.
//   dir          : Combing direction.
//   combGap      : Spacing between tines.
//   nPasses      : Number of nearby tines to approximate drift by.
vec2 rdNonpareil(vec2 p, float combR, vec2 combDir, float combGap, int nPasses) {
  vec2  dir = normalize(combDir);
  vec2  n = rot90(dir);
  float y = dot(p, n);
  float passGap = float(nPasses) * combGap; // wider spacing between passes for nicer falloff + overlap
  vec2  rdf = vec2(0.);
  for (int k = 0; k < nPasses; k++) {
    float yOffset = float(k) * combGap;
    float height = minCombDist(y + yOffset, passGap);
    rdf += rdLine1DS(height, combR) * dir;
  }
  return rdf;
}

// RDF for Nonpareil pattern with comb gap noise.
// Inputs:
//   p            : Evaluation point.
//   r            : Tine radius.
//   dir          : Combing direction.
//   combGap      : Spacing between tines.
//   combGapNoise : Amplitude of tine position variation (± this value).
vec2 rdNonpareilNoisy(vec2 p, float r, vec2 dir, float combGap, float combGapNoise) {
  dir = normalize(dir);
  vec2  n = rot90(dir);
  float y = dot(p, n);
  float dyMax = r * RDSEGMENT_MASK_R_FACTOR + combGap;
  int   dkMax = int(ceil(dyMax / combGap));
  int   k0 = int(round(y / combGap)); // closest (unpeturbed) tine.
  vec2  rdf = vec2(0.);
  for (int k = k0 - dkMax; k <= k0 + dkMax; k++) {
    float noisek = 2.*iqhash(float(k)) - 1.; // ∈[-1,1)
    float yk = combGap * float(k) + combGapNoise * noisek;
    rdf += rdLine1DS(abs(y - yk), r) * dir;
  }
  return rdf;
}

// RDF for Gel-Git pattern.
vec2 rdGelGit(vec2 p, float combR, vec2 combDir, float combGap, int nPasses) {
  vec2  dir = normalize(combDir);
  vec2  n = rot90(dir);
  float y = dot(p, n);
  float passGap = float(nPasses) * combGap * 2.; // wider spacing between passes for nicer falloff + overlap
  vec2  rdf = vec2(0.);
  // GIT ("left")
  for (int k = 0; k < nPasses; k++) {
    float yOffset = (0.5 + float(k)) * combGap * 2.;
    float height = minCombDist(y + yOffset, passGap);
    rdf -= rdLine1DS(height, combR) * dir;
  }
  // GEL ("right")
  for (int k2 = 0; k2 < nPasses; k2++) {
    float yOffset = float(k2) * combGap * 2.;
    float height = minCombDist(y + yOffset, passGap);
    rdf += rdLine1DS(height, combR) * dir;
  }
  return rdf;
}

// Mixwell brush matrix for relative position, v, and radius eps.
mat2 getMixwellBrushMatrix(vec2 v, float eps) {
  float R2 = dot(v, v);
  float e2 = eps*eps;
  float s  = R2 + e2;

  // invD = 1/(s^(3/2)) = 1/(s*sqrt(s))
  float invSqrtS = inversesqrt(s);
  float invS = invSqrtS*invSqrtS;
  float invD = invS*invSqrtS;

  float invR = inversesqrt(max(R2, 1e-20)); // guard 1/R at v≈0
  float R    = R2*invR; // sqrt(R2);  WIN: Saves an XU instruction!

  // Afd = 1 - R*(R2 + 2e2)/d  == 1 - sqrt(R2)*(R2 + 2e2)*invD
  float Afd = 1.0 - R*(R2 + 2.0*e2)*invD;

  // Bfd = e2/(R*d) == e2*(1/R)*invD
  float Bfd = e2*invR*invD;

  // K = Afd*I + Bfd*(v v^T)
  float xx = Bfd*v.x*v.x;
  float xy = Bfd*v.x*v.y;
  float yy = Bfd*v.y*v.y;

  return mat2(Afd + xx, xy, xy, Afd + yy);
}

// Reverse drift through Mixwell flow of radius-eps brush moving a→b. Computed using adaptive midpoint integration.
vec2 rdMixwellBrushAdaptiveMidpoint(vec2 p0, float eps, vec2 a, vec2 b) {
  // Step brush position backwards from b to a, advecting p to compute rev-drift (p-p0):
  vec2  uBrush = a - b; // rev brush step
  float L = length(uBrush);
  if (L <= 1e-20) return vec2(0.);
  vec2  dir = uBrush/L; // rev brush dir
  float distLeft = L; // brush motion left
  vec2  p = p0; // reverse-drifted point position (init: p0)
  while (distLeft > 0.) {
    vec2  v = p - b; // rel pos from end brush goal
    float R = length(v);
    float dL = min(distLeft, 0.10*max(eps, R)); // adaptive stepsize (spatially continuous errors)
    distLeft -= dL;

    // MIDPOINT STEP:  dp = K(vmid) db
    vec2  db = dL*dir; // Δbrush
    mat2  K  = getMixwellBrushMatrix(v, eps); // K(v)
    vec2  dp = K*db; // Euler approx, dp = K(v) db

    vec2  vmid = v + 0.5*(dp - db); // v' = p' - b' = v + 0.5*(dp - db)
    mat2  Kmid = getMixwellBrushMatrix(vmid, eps); // K(vmid)
    vec2  dpmid = Kmid*db; // Midpoint step

    p += dpmid; // update point (rd midpoint approx)
    b += db; // update brush location
  }
  return p - p0; // reverse-drift displacement
}

// Reverse drift for line segment (a→b) using a time-stepped Mixwell Brush (B) of radius r.
vec2 rdSegmentMBrush(vec2 p, float r, vec2 a, vec2 b) {
  return rdMixwellBrushAdaptiveMidpoint(p, r, a, b);
}

// Combs a→b (performs insert/remove flows at begin/end)
vec2 rdSegment(vec2 p, float r, vec2 a, vec2 b) {
  // Optional: LOCAL MASK (zero beyond dMax ∝ r):
  float d = sdSegment(p, a, b);
  float dMax = RDSEGMENT_MASK_R_FACTOR * r; // ADJUST RDSEGMENT_MASK_R_FACTOR TO TASTE
  if (d >= dMax) return vec2(0.);
  float mask = 1. - smoothstep(0.5*dMax, dMax, d); // blend-to-zero factor.

  //return mask * rdSegmentM(p, r, a, b); // Mixwell Newton solver (full lib only)
  return mask * rdSegmentMBrush(p, r, a, b); // Mixwell Brush solver
}

// Combs a→b (performs insert/remove flows at begin/end), with reverse option.
// @param reverse - Swaps a↔b.
vec2 rdSegmentRev(vec2 p, float r, vec2 a, vec2 b, bool reverse) {
  vec2 head = reverse ? b : a;
  vec2 tail = reverse ? a : b;
  return rdSegment(p, r, head, tail);
}

/**
 * Triangle Wave RDF.
 *
 * Uses rdSegments to construct a triangle wave parameterized like a sine wave
 * at the origin with user specified direction and parameters.
 * Uses sparse evaluation of masked rdSegments only near p.
 *
 * Inputs:
 *  p   - Evaluation point.
 *  r   - Tine radius.
 *  dir - Direction of wave centerline.
 *  L   - Wavelength
 *  A   - Signed amplitude. Use A=0 for broken and dashed lines.
 *  broken - Broken segments using doubly reversed rdSegments.
 *  dashed - Draws only every other segment.
 */
vec2 rdTriWave(vec2 p, float r, vec2 dir, float L, float A, bool broken, bool dashed) {
  vec2 p0 = p; // Initial position for reverse drift calc (p - p0)
  dir = normalize(broken ? -dir : dir); // Change direction for reversed rdSegments flow trend

  // Project p onto line --> c and get coords for p as (x, y)
  vec2  c = dot(p, dir) * dir;
  float x = dot(c, dir);
  float y = length(p - c); // Unsigned distance to line
  float segR = sqrt(A*A + L*L/16.0);
  float R = r * RDSEGMENT_MASK_R_FACTOR + segR; // Bounding radius of point w.r.t. qi

  float H = L * 0.5;
  // Guard against a point outside the influence band (R*R - y*y < 0 -> sqrt is NaN) and a
  // degenerate wavelength (H <= 0). Casting NaN/Inf to int for the loop bounds below is
  // undefined behavior and can produce a runaway loop that hangs the GPU. Outside the band
  // no segment contributes, so return zero drift.
  float disc = R*R - y*y;
  if (disc <= 0.0 || H <= 0.0) return vec2(0.0);
  float Rx = sqrt(disc); // Influence "radius" about x on line
  int iR = int(ceil((x + Rx) / H)); // max i
  int iL = int(floor((x - Rx) / H)); // min i

  vec2 vd = 0.5 * H * dir;
  vec2 vp = A * rot90(dir);

  for (int i = iR; i >= iL; i--) { // Reverse sweep
    float si = (abs(i) % 2 == 0) ? -1.0 : 1.0; // -1 even | +1 odd
    if (!dashed || (dashed && si < 0.0)) {
      vec2 qi = dir * H * float(i);
      vec2 ai = qi - vd + si * vp;
      vec2 bi = qi + vd - si * vp;
      p += rdSegmentRev(p, r, ai, bi, broken);
    }
  }

  return p - p0; // Reverse drift displacement
}

vec2 rdTriWaveComb(vec2 p, float r, vec2 dir, float L, float A, bool broken, bool dashed, float combGap) {
  dir = normalize(dir);
  vec2  n = rot90(dir);
  float y = dot(p, n);
  float R = A + r * RDSEGMENT_MASK_R_FACTOR; // 1D perp-influence radius of a wave centerline
  if (combGap <= 0.0) return vec2(0.0); // degenerate spacing -> division below would be Inf (GPU hang)
  int dk = int(ceil(R / combGap)); // Conservative range of wave indices influencing p
  int kp = int(round(y / combGap)); // Closest wave index (where origin wave is k=0)

  vec2 rdf = vec2(0.);
  for (int k = kp - dk; k <= kp + dk; k++) { // Sum nearby(p) wave RDFs:
    float yk = float(k) * combGap; // Perp offset of k'th centerline
    vec2  pk = p - yk * n; // Translate k'th wave to origin
    rdf += rdTriWave(pk, r, dir, L, A, broken, dashed); // Accumulate RDF of k'th triwave
  }
  return rdf;
}

/// END////////////////////////////////////////////////////////////////
