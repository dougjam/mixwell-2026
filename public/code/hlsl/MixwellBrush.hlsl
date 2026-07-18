// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Doug L. James and Ethan James

///////////////////////////////////////////////////////////////////////
////  Mixwell-Lite Library Functions /// @author Doug L James, 2026 ///
///////////////////////////////////////////////////////////////////////

static const float TWO_PI = 6.28318530718f; // 2π 
static const float PI = 3.14159265358979323846f; // π
static const float PI_2 = 1.57079632679489661923f; // π/2

// Cutoff distance (as multiple of tine radius) beyond which rdSegment is zero.
static const float RDSEGMENT_MASK_R_FACTOR = 10.0f;

// Euclidean mod 
float emod(float x, float n)
{
    return frac(x / n) * n;
}
float2 emod(float2 x, float2 n)
{
    return frac(x / n) * n;
}
float3 emod(float3 x, float3 n)
{
    return frac(x / n) * n;
}

/*** [BEGIN] SDF FUNCTIONS *******************************************/

float sdSegment(float2 p, float2 a, float2 b)
{
    float2 pa = p - a;
    float2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0f, 1.0f);
    return length(pa - ba * h);
}

/*** [END] SDF FUNCTIONS *******************************************/

/*****************************************************************************/
/*** [BEGIN] COLOR & TEST IMAGES                       ***********************/
/*****************************************************************************/

// Paint texture
float3 paintChocolate(float2 q)
{
    float theta = 0.3f;
    float c = cos(theta);
    float s = sin(theta);
    float2 p = float2(c * q.x - s * q.y, s * q.x + c * q.y);
    float k0 = 45.0f;
    float k1 = 29.0f;
    float phi0 = 3.0f;
    float phi1 = 2.0f;
    float3 col0 = float3(0.6862745098f, 0.4f, 0.1490196078f); // rgb(175, 102,  38);
    float3 col1 = float3(0.6901960784f, 0.9411764706f, 0.9921568627f); // rgb(176, 240, 253);
    float3 colChocolate = float3(0.1490196078f, 0.0862745098f, 0.0901960784f); // rgb(38,22,23);
    float splat0 = smoothstep(0.5f, 0.64f,
                              sin(k0 * p.x * (1.0f - 0.153f * p.x) + phi0) * sin(k0 * p.y * (1.0f + 0.6f * p.x) + phi0) *
                                  (1.0f - 0.2f * sin(12.0f * p.x * p.x)));
    float splat1 = smoothstep(0.5f, 0.64f,
                              sin(k1 * p.x * (1.0f + 0.230f * p.x) + phi1) * cos(k1 * p.y * (1.0f - 0.1f * p.x) + phi1) *
                                  (1.0f - 0.2f * sin(12.0f * p.x * p.y)));
    float3 col = lerp(colChocolate + splat0 * col0, col1, splat1);

    return col;
}

float3 paintTestSquare(float2 q) 
{
    return float3(1.0f, 1.0f, 1.0f) * smoothstep(0.1f, 0.11f, q.x) * smoothstep(0.2f, 0.19f, q.x) *
           smoothstep(0.1f, 0.11f, q.y) * smoothstep(0.2f, 0.19f, q.y);
}

float3 paintStripes(float2 q)
{
    return pow(smoothstep(0.0f, 1.0f, frac(6.0f * q.y + sin(33.0f * q.x))), 3.0f) * float3(1.0f, 1.0f, 1.0f);
}

// Adapted from https://webgl-operate.org/examples/canvassize-example.html 
float3 paintTestImage(float2 fragCoord)
{
    const float CELL_WIDTH = 1.0f / 32.0f;

    float3 x3 = float3(fragCoord.x, fragCoord.x + 1.0f, fragCoord.x + 2.0f);
    float3 y3 = float3(fragCoord.y, fragCoord.y + 1.0f, fragCoord.y + 2.0f);

    float3 x = step(emod(x3, 3.0f), 1.0f); // emod
    float3 y = step(emod(y3, 3.0f), 1.0f); // emod

    float cell = step(emod(fragCoord.x * CELL_WIDTH + floor(fragCoord.y * CELL_WIDTH), 2.0f), 1.0f); // emod

    return lerp(x, y, cell);
}

float3 paintCheckerboard(float2 q, float h) 
{
    int2 cell = int2(floor(q / h));
    return (cell.x + cell.y) & 1;
}

float3 splatBlobRows(float2 p, float3 colBG, float3 colBlob, float HX, float HY, float dY, float blobRadius, float isOddRow) 
{
    float Yoffset = (isOddRow) ? 0.5f * HY : 0.f;

    // SNAP p to closest horizontal row:
    float ySnap = Yoffset + round((p.y - Yoffset) / HY) * HY; // y of closest row
    p.y -= ySnap;
    p.x -= sin(437.5453 * ySnap) * 437.5453; // SHIFT X per ROW

    // STRING OF BLOBS ON y=0 AXIS:
    float F = 1239.f + ySnap; // nat freq for variation

    // Mission: Find our blob i:
    float x0 = HX * floor(p.x / HX);
    float x1 = x0 + HX; // ceil
    float2 p0 = float2(x0, dY * sin(F * x0));
    float2 p1 = float2(x1, dY * sin(F * x1));
    float D0 = dot(p - p0, p - p0);
    float D1 = dot(p - p1, p - p1);
    float iC = (D0 < D1) ? round(x0 / HX) : round(x1 / HX);

    // Render blob: It takes three blobs to raise a blob:
    float xC = iC * HX; // center (i)
    float xL = xC - HX; // left   (i-1)
    float xR = xC + HX; // right  (i+1)
    float yC = dY * sin(F * xC); // ignore Yoffset here
    float yL = dY * sin(F * xL);
    float yR = dY * sin(F * xR);
    float2 pC = float2(xC, yC);
    float2 pL = float2(xL, yL);
    float2 pR = float2(xR, yR);
    float e2 = 0.00001 * HX * HX;
    float DC = dot(p - pC, p - pC) + e2;
    float DL = dot(p - pL, p - pL) + e2;
    float DR = dot(p - pR, p - pR) + e2;
    float f = 1.f / DC - 1.f / DL - 1.f / DR;

    // Implicit blob size hint:
    f -= 1.f / (blobRadius * blobRadius);

    float reg = smoothstep(HX, 2.f * HX, max(0.f, f));
    return lerp(colBG, colBlob, reg);
}

static const float3 palette01[6] =
{
    float3(0, 0, 1), // blue
    float3(1, 0, 0), // red
    float3(0, 1, 1), // cyan
    float3(1, 1, 0), // yellow
    float3(1, 1, 1), // white
    float3(1, 1, 1), // white (duplicate)
};
//------------------------------------------------------------------------------
// Palette 1: Coolors example (brown blue)
// 1a344d,1e8eb6,fc9843,5a1800,f7f5f6
//------------------------------------------------------------------------------
static const float3 paletteCoolors1[6] =
{
    float3(0.1019608, 0.2039216, 0.3019608),
    float3(0.3529412, 0.09411765, 0.0),
    float3(0.1176471, 0.5568628, 0.7137255),
    float3(0.9882353, 0.5960785, 0.2627451),
    float3(0.9686275, 0.9607843, 0.9647059),
    float3(0.9686275, 0.9607843, 0.9647059),
};

//------------------------------------------------------------------------------
// Palette: fb6107,f3de2c,7cb518,5c8001,fbb02d
// Names: Blaze Orange, Golden Glow, Lime Moss, Forest Moss, Sunflower Gold
//------------------------------------------------------------------------------
static const float3 paletteGoldenMeadow[6] =
{
    float3(0.9843137, 0.3803922, 0.0274510), // fb6107
    float3(0.3607843, 0.5019608, 0.0039216), // 5c8001
    float3(0.9843137, 0.6901961, 0.1764706), // fbb02d
    float3(0.4862745, 0.7098039, 0.0941176), // 7cb518
    float3(0.9529412, 0.8705882, 0.1725490), // f3de2c
    float3(0.9529412, 0.8705882, 0.1725490), // f3de2c
};

float3 paintBlobsWithPalette(float2 p, const float3 palette[6])
{
    float HX = 0.25; // X CELL SIZE
    float HY = 1.f; // ROW SPACING
    float dY = HX / 10.f; // Y POSITION VARIATION
    float blobRadius = 2.f * HX; // BLOB SIZE HINT FOR SMALLER BLOBS

    float3 col = float3(0, 0, 0); // Background
    col = splatBlobRows(p, col, palette[0], HX, HY, dY, 2.f * HX, false);
    col = splatBlobRows(p, col, palette[1], HX, HY, dY, 2.f * HX, true);
    col = splatBlobRows(p, col, palette[2], HX, HY, dY, HX / 2., false);
    col = splatBlobRows(p, col, palette[3], HX, HY, dY, HX / 3., true);
    col = splatBlobRows(p, col, palette[4], HX, HY, dY, HX / 6., false);
    col = splatBlobRows(p, col, palette[5], HX, HY, dY, HX / 7., true);

    return col;        
}

float3 paintBlobs(float2 p) 
{
    return paintBlobsWithPalette(p, paletteGoldenMeadow);
}

/*****************************************************************************/
/*** [ END ] COLOR & TEST IMAGES                       ***********************/
/*****************************************************************************/

/*** [BEGIN] UTILITIES *******************************************/

// Returns (-y,x) given v=(x,y).
float2 rot90(float2 v)
{
    return float2(-v.y, v.x);
}

// Simple pseudorandom float-to-float[0,1] hash.
float iqhash(float n)
{
    return frac(sin(n) * 43758.5453);
}

/*** [END] UTILITIES *******************************************/


/*****************************************************************************/
/*** [BEGIN] REVERSE-DRIFT FIELD (RDF) IMPLEMENTATIONS                      **/
/*****************************************************************************/

// Line RDF: Matched series approximation to 1D drift.
// Input: height above flow line, and cylinder radius, r.
float rdLine1DS(float height, float r)
{ 
    float y = height / r;
    float dx = 0.f; // drift = 5.f * r / (0.2f + pow(eta, 3.f));

    float eps = 0.002f;
    y = sqrt(y * y + eps * eps); // y_eps

    if (y > 6.50416858646776f)
    {
        float h = 1.f / y;
        float h2 = h * h;
        float h3 = h * h2;
        float poly = ((((6615.f * h2 - 1960.f) * h2 + 600.f) * h2 - 192.f) * h2 + 64.f);
        dx = -(PI / 256.f) * h3 * poly;
    }
    else if (y > 0.8220844420096408f)
    {
        float dy = y - 2.3f;
        float num = (((((-1.01973e-7f * dy + 1.77539e-6f) * dy - 0.0068946f) * dy - 0.043355f) * dy - 0.0937878f) * dy - 0.0413839f);
        float den = ((((((0.00875686f * dy + 0.115772f) * dy + 0.665761f) * dy + 2.08615f) * dy + 3.66495f) * dy + 3.26035f) * dy + 1.0f);
        dx = num / den;
    }
    else
    {
        float z = y * y;
        float A = ((((0.00015811568f * z - 0.00096477622f) * z + 0.0076619254f) * z - 0.16369764f) * z - 0.039720771f);
        float B = ((((-0.00018775463f * z + 0.0010681152f) * z - 0.0073242188f) * z + 0.09375f) * z + 0.5f);
        dx = A + B * log(y);
    }

    return 2.0f * r * dx; // UNDO UNIT-RADIUS XFORM & *2 for full drift.
}

// Returns rdLine1DS series implementation of 1D drift. Provided for "backwards convenience."
float drift1D(float height, float r)
{
    return rdLine1DS(height, r);
}

// RDF at p for a circle(r) passing along an infinite line in (dir)ection passing through origin.
float2 rdLine(float2 p, float r, float2 dir)
{
    dir = normalize(dir);
    float2 n = rot90(dir); // float2(-dir.y, +dir.x);
    float height = dot(p, n);
    float2 rdf = rdLine1DS(height, r) * dir;
    return rdf;
}

// Min distance from y to a tine of a comb with pitch hy, rooted at the origin.
float minCombDist(float y, float hy)
{
    return hy * abs(frac(y / hy - 0.5f) - 0.5f);
}

// RDF for Nonpareil pattern.
// Inputs:
//   p            : Evaluation point.
//   r            : Tine radius.
//   dir          : Combing direction.
//   combGap      : Spacing between tines.
//   nPasses      : Number of nearby tines to approximate drift by.
float2 rdNonpareil(float2 p, float combR, float2 combDir, float combGap, int nPasses)
{
    float2 dir = normalize(combDir);
    float2 n = rot90(dir);
    float y = dot(p, n);
    float passGap = float(nPasses) * combGap; // wider spacing between passes for nicer falloff + overlap
    float2 rdf = float2(0.f, 0.f);
    for (int k = 0; k < nPasses; k++)
    {
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
float2 rdNonpareilNoisy(float2 p, float r, float2 dir, float combGap, float combGapNoise)
{
    dir = normalize(dir);
    float2 n = rot90(dir);
    float y = dot(p, n);
    float dyMax = r * RDSEGMENT_MASK_R_FACTOR + combGap;
    int dkMax = (int) (ceil(dyMax / combGap));
    int k0 = (int) (round(y / combGap)); // closest (unpeturbed) tine.
    float2 rdf = float2(0.f, 0.f);
    for (int k = k0 - dkMax; k <= k0 + dkMax; k++)
    {
        float noisek = 2.f * iqhash(float(k)) - 1.f; // ∈[-1,1)
        float yk = combGap * float(k) + combGapNoise * noisek;
        ////if(iqhash(noisek*FUDGE) > 0.12) // Optional tine dropout (skip for now)
        rdf += rdLine1DS(abs(y - yk), r) * dir;
    }
    return rdf;
}

// RDF for Gel-Git pattern.
float2 rdGelGit(float2 p, float combR, float2 combDir, float combGap, int nPasses)
{
    float2 dir = normalize(combDir);
    float2 n = rot90(dir);
    float y = dot(p, n);
    float passGap = float(nPasses) * combGap * 2.f; // wider spacing between passes for nicer falloff + overlap
    float2 rdf = float2(0.f, 0.f);
    // GIT ("left")
    for (int k = 0; k < nPasses; k++)
    {
        float yOffset = (0.5f + float(k)) * combGap * 2.f;
        float height = minCombDist(y + yOffset, passGap);
        rdf -= rdLine1DS(height, combR) * dir;
    }
    // GEL ("right")
    for (int k2 = 0; k2 < nPasses; k2++)
    {
        float yOffset = float(k2) * combGap * 2.f;
        float height = minCombDist(y + yOffset, passGap);
        rdf += rdLine1DS(height, combR) * dir;
    }
    return rdf;
}

// Mixwell brush matrix for relative position, v, and radius eps. 
float2x2 getMixwellBrushMatrix(float2 v, float eps)
{
    float R2 = dot(v, v);
    float e2 = eps * eps;
    float s = R2 + e2;

    // invD = 1/(s^(3/2)) = 1/(s*sqrt(s))
    float invSqrtS = rsqrt(s);
    float invS = invSqrtS * invSqrtS;
    float invD = invS * invSqrtS;

    float invR = rsqrt(max(R2, 1e-20f)); // guard 1/R at v≈0
    float R = R2 * invR; // sqrt(R2);  WIN: Saves an XU instruction!

    // Afd = 1 - R*(R2 + 2e2)/d  == 1 - sqrt(R2)*(R2 + 2e2)*invD
    float Afd = 1.0f - R * (R2 + 2.0f * e2) * invD;

    // Bfd = e2/(R*d) == e2*(1/R)*invD
    float Bfd = e2 * invR * invD;

    // K = Afd*I + Bfd*(v v^T)
    float xx = Bfd * v.x * v.x;
    float xy = Bfd * v.x * v.y;
    float yy = Bfd * v.y * v.y;

    return float2x2(Afd + xx, xy, xy, Afd + yy);
}

// Reverse drift through Mixwell flow of radius-eps brush moving a→b. Computed using adaptive midpoint integration. 
float2 rdMixwellBrushAdaptiveMidpoint(float2 p0, float eps, float2 a, float2 b)
{
    // Step brush position backwards from b to a, advecting p to compute rev-drift (p-p0):
    float2 uBrush = a - b; // rev brush step
    float L = length(uBrush);
    if (L <= 1e-20f)
        return float2(0, 0);
    float2 dir = uBrush / L; // rev brush dir
    float distLeft = L; // brush motion left
    float2 p = p0; // reverse-drifted point position (init: p0)
    while (distLeft > 0.f)
    {
        float2 v = p - b; // rel pos from end brush goal
        float R = length(v);
        float dL = min(distLeft, 0.10f * max(eps, R)); // adaptive stepsize (spatially continuous errors)
        distLeft -= dL;

        // MIDPOINT STEP:  dp = K(vmid) db
        float2 db = dL * dir; // Δbrush
        float2x2 K = getMixwellBrushMatrix(v, eps); // K(v)
        float2 dp = mul(K, db); // Euler approx, dp = K(v) db

        float2 vmid = v + 0.5f * (dp - db); // v' = p' - b' = v + 0.5*(dp - db)
        float2x2 Kmid = getMixwellBrushMatrix(vmid, eps); // K(vmid)
        float2 dpmid = mul(Kmid, db); // Midpoint step

        p += dpmid; // update point (rd midpoint approx)
        b += db; // update brush location
    }
    return p - p0; // reverse-drift displacement
}

// Reverse drift for line segment (a→b) using a time-stepped Mixwell Brush (B) of radius r. 
float2 rdSegmentMBrush(in float2 p, in float r, in float2 a, in float2 b)
{
    return rdMixwellBrushAdaptiveMidpoint(p, r, a, b);
}

// Combs a→b (performs insert/remove flows at begin/end)
float2 rdSegment(float2 p, float r, float2 a, float2 b)
{
    // Optional: LOCAL MASK (zero beyond dMax ∝ r):
    float d = sdSegment(p, a, b);
    float dMax = RDSEGMENT_MASK_R_FACTOR * r; // ADJUST RDSEGMENT_MASK_R_FACTOR TO TASTE
    if (d >= dMax)
        return float2(0.f, 0.f);
    float mask = 1.f - smoothstep(0.5f * dMax, dMax, d); // blend-to-zero factor.

    // return mask * rdSegmentM(p, r, a, b); // Mixwell Newton solver
    return mask * rdSegmentMBrush(p, r, a, b); // Mixwell Brush solver
}

// Combs a→b (performs insert/remove flows at begin/end), with reverse option.
// @param reverse - Swaps a↔b.
float2 rdSegmentRev(float2 p, float r, float2 a, float2 b, bool reverse)
{
    float2 head = (reverse ? b : a);
    float2 tail = (reverse ? a : b);
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
float2 rdTriWave(float2 p, float r, float2 dir, float L, float A, bool broken, bool dashed)
{
    float2 p0 = p; // Initial position for reverse drift calc (p - p0)
    dir = normalize(broken ? -dir : dir); // Change direction for reversed rdSegments flow trend

    // Project p onto line --> c and get coords for p as (x, y)
    float2 c = dot(p, dir) * dir;
    float x = dot(c, dir);
    float y = length(p - c); // Unsigned distance to line
    float segR = sqrt(A * A + L * L / 16.0f);
    float R = r * RDSEGMENT_MASK_R_FACTOR + segR; // Bounding radius of point w.r.t. qi

    float H = L * 0.5f;
    float Rx = sqrt(R * R - y * y); // Influence "radius" about x on line
    int iR = (int) ceil((x + Rx) / H); // max i
    int iL = (int) floor((x - Rx) / H); // min i

    float2 vd = 0.5f * H * dir;
    float2 vp = A * rot90(dir);

    for (int i = iR; i >= iL; i--)
    { // Reverse sweep
        float si = (abs(i) % 2 == 0) ? -1.0f : 1.0f; // -1 even | +1 odd
        if (!dashed || (dashed && si < 0.0f))
        {
            float2 qi = dir * H * float(i);
            float2 ai = qi - vd + si * vp;
            float2 bi = qi + vd - si * vp;
            p += rdSegmentRev(p, r, ai, bi, broken);
        }
    }

    return p - p0; // Reverse drift displacement
}

float2 rdTriWaveComb(float2 p, float r, float2 dir, float L, float A, bool broken, bool dashed, float combGap)
{
    dir = normalize(dir);
    float2 n = rot90(dir);
    float y = dot(p, n);
    float R = A + r * RDSEGMENT_MASK_R_FACTOR; // 1D perp-influence radius of a wave centerline
    int dk = (int) ceil(R / combGap); // Conservative range of wave indices influencing p
    int kp = (int) round(y / combGap); // Closest wave index (where origin wave is k=0)

    float2 rdf = float2(0.f, 0.f);
    for (int k = kp - dk; k <= kp + dk; k++)
    { // Sum nearby(p) wave RDFs:
        float yk = float(k) * combGap; // Perp offset of k'th centerline
        float2 pk = p - yk * n; // Translate k'th wave to origin
        rdf += rdTriWave(pk, r, dir, L, A, broken, dashed); // Accumulate RDF of k'th triwave
    }
    return rdf;
}

/// END////////////////////////////////////////////////////////////////
////  Mixwell-Lite Library Functions /// @author Doug L James, 2026 ///
///////////////////////////////////////////////////////////////////////
