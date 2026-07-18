// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Doug L. James and Ethan James

///////////////////////////////////////////////////////////////////////
////  Mixwell Library Functions /// @author Doug L James, 2025 ////////
///////////////////////////////////////////////////////////////////////

const float PI               = 3.14159265358979323846; // π
const float PI_2             = 1.57079632679489661923; // π/2

// Constant that determines cutoff distance (as multiple of tine radius) beyond which rdSegment is zero.
const float RDSEGMENT_MASK_R_FACTOR = 10.;


/*** [BEGIN] SDF FUNCTIONS *********1**********************************/
float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
// Unsigned distance from the infinite line specified by a ray origin (ro) and direction (unit rd). 
float udLine(vec2 p, vec2 ro, vec2 rd) {
    vec2 v = p-ro;
    return length( v - dot(v,rd)*rd/dot(rd,rd) );
}
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}
float sdTriangle( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2 )
{
    vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
    vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    float  s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                     vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                     vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
    return -sqrt(d.x)*sign(d.y);
}
/*** [END] SDF FUNCTIONS *******************************************/

/*****************************************************************************/
/*** [BEGIN] COLOR & TEST IMAGES                       ***********************/
/*****************************************************************************/

// Matlab Jet colormap :/ 
vec4 jet(float x) {
    float r = clamp((x < 0.7) ? (4.0 * x - 1.5) : (-4.0 * x + 4.5), 0.0, 1.0);
    float g = clamp((x < 0.5) ? (4.0 * x - 0.5) : (-4.0 * x + 3.5), 0.0, 1.0);
    float b = clamp((x < 0.3) ? (4.0 * x + 0.5) : (-4.0 * x + 2.5), 0.0, 1.0);
    return vec4(r, g, b, 1.0);
}

vec3 rgb(int r, int g, int b) {
  return vec3(float(r), float(g), float(b))/255.;
}

vec3 quantizeColor(vec3 c, float n, bool bands) {
    vec3  res     = floor(c*n)/n;
    if(bands) res *= smoothstep(-0.0001, +0.0001, length(c-res)-0.005);
    return res;
}

// Paint texture
vec3 paintChocolate(vec2 q) {  
  float theta = 0.3;
  float c     = cos(theta);
  float s     = sin(theta);
  vec2  p     = vec2(c*q.x - s*q.y, s*q.x + c*q.y);
  float k0    = 45.;
  float k1    = 29.;
  float phi0  = 3.;
  float phi1  = 2.;
  vec3  col0  = vec3(0.6862745098, 0.4         , 0.1490196078);        //rgb(175, 102,  38);
  vec3  col1  = vec3(0.6901960784, 0.9411764706, 0.9921568627);        //rgb(176, 240, 253);
  vec3  colChocolate = vec3(0.1490196078, 0.0862745098, 0.0901960784); //rgb(38,22,23);
  float splat0 = smoothstep(0.5, 0.64, sin(k0*p.x*(1.-0.153*p.x)+phi0)*sin(k0*p.y*(1.+0.6*p.x)+phi0)*(1.-0.2*sin(12.*p.x*p.x)));
  float splat1 = smoothstep(0.5, 0.64, sin(k1*p.x*(1.+0.230*p.x)+phi1)*cos(k1*p.y*(1.-0.1*p.x)+phi1)*(1.-0.2*sin(12.*p.x*p.y)));
  vec3  col    = mix(colChocolate + splat0*col0, col1, splat1);// + splat1*col1;
  
  // TEST SQUARE:
  //col = vec3(1.)* smoothstep(0.1, 0.11, q.x) * smoothstep(0.2, 0.19, q.x) * smoothstep(0.1, 0.11, q.y) * smoothstep(0.2, 0.19, q.y);
  
  return col;
}
vec3 paintStripes(vec2 q) {
    //return pow(smoothstep(0., 1., fract(6.*q.y+sin(33.*q.x*q.y))),3.)* vec3(1);// < 0.5 ? vec3(1) : vec3(0);
    return pow(smoothstep(0., 1., fract(6.*q.y+sin(33.*q.x))),3.)* vec3(1);// < 0.5 ? vec3(1) : vec3(0);
}
// Adapted from https://webgl-operate.org/examples/canvassize-example.html
vec3 paintTestImage(vec2 fragCoord) {
    const float CELL_WIDTH = 1.0 / 32.0;
    
    vec3 x3 = vec3(fragCoord.x) + vec3(0.0, 1.0, 2.0);
    vec3 y3 = vec3(fragCoord.y) + vec3(0.0, 1.0, 2.0);

    vec3 x = step(mod(x3, vec3(3.0)), vec3(1.0));
    vec3 y = step(mod(y3, vec3(3.0)), vec3(1.0));
    
    float cell = step(mod(fragCoord.x*CELL_WIDTH + floor(fragCoord.y*CELL_WIDTH), 2.0), 1.0);

    return mix(x, y, cell);
}
vec3 paintCheckerboard(vec2 q, float h) {
    return vec3(mod( dot(mod ( floor(q/h), 2.),vec2(1)), 2.));
}
/*****************************************************************************/
/*** [ END ] COLOR & TEST IMAGES                       ***********************/
/*****************************************************************************/


/*** [BEGIN] UTILITIES *******************************************/
vec2 rotate(vec2 v, float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return vec2(
        c * v.x - s * v.y,
        s * v.x + c * v.y
    );
}

// Returns (-y,x) given v=(x,y).
vec2 rot90(vec2 v) {
  return vec2(-v.y, v.x);
}

// Normalizes p if ‖p‖<1.
vec2 projectOutsideUnitDisk(vec2 p) {
  float R2 = p.x*p.x + p.y*p.y; 
  return (R2 >= 1.) ? p : p/sqrt(R2); 
}

// Simple pseudorandom float-to-float[0,1] hash.  
float iqhash(float n) { return fract(sin(n)*43758.5453); }

/*** [END] UTILITIES *******************************************/



/*****************************************************************************/
/*** [BEGIN] CARLSON ITERATIONS AND ELLIPTIC FUNCTIONS ***********************/
/*****************************************************************************/
const int   CARLSON_MAX_ITER = 15;       // Maximum number of iterations
const float CARLSON_TOL      = 0.001;    // Tolerance for convergence

// Carlson's RF function [Carlson 1995, p.16] (as .x) and the final "n" iteration# (as .y).
vec2 CarlsonRFn(float x, float y, float z) {
    float A0 = (x + y + z) * 0.3333333333333333;;
    float An = A0;
    float Q  = pow(3.0 * CARLSON_TOL, -1.0/6.0) * max(max(abs(A0-x), abs(A0-y)), abs(A0-z));
    float xn = x;
    float yn = y;
    float zn = z;
    
    float n4 = 1.0;
    int   n  = 0;
    for (n=0; n<CARLSON_MAX_ITER; n++) {
        if (Q <= CARLSON_TOL * An) { 
            break;
        }
        float lambda = sqrt(xn * yn) + sqrt(xn * zn) + sqrt(yn * zn); 
        An = (An + lambda) * 0.25;
        xn = (xn + lambda) * 0.25;
        yn = (yn + lambda) * 0.25;
        zn = (zn + lambda) * 0.25;
        Q  *= 0.25;
        n4 *= 4.0; // 4^n for break or CARLSON_MAX_ITER
    }
    float X  = (A0 - x)/(n4 * An);
    float Y  = (A0 - y)/(n4 * An);
    float Z  = -X - Y; 
    float E2 = X*Y - Z*Z; // X*Y + Y*Z + Z*X;
    float E3 = X*Y*Z;
    float RF = (1. - (E2/10.) + (E3/14.) + (E2*E2/24.) - (3./44.*E2*E3)) / sqrt(An);
    return vec2(RF,n);
}

// Carlson's RD function [Carlson 1995, p.20] (as .x) and the final "n" iteration# (as .y).
vec2 CarlsonRDn(float x, float y, float z) {
    float A0  = (x + y + 3.0*z)/5.0;
    float An  = A0;
    float Q   = pow(CARLSON_TOL/4.0, -1.0/6.0) * max(max(abs(A0-x), abs(A0-y)), abs(A0-z));
    float xn  = x;
    float yn  = y;
    float zn  = z;
    float Sum = 0.0;
    
    float n4  = 1.0;
    int   n   = 0;
    for (n=0; n<CARLSON_MAX_ITER; n++) {
    
        float lambda = sqrt(xn * yn) + sqrt(xn * zn) + sqrt(yn * zn); 
        Sum += 1.0 / ( n4 * sqrt(zn) * (zn + lambda) );
    
        if (Q <= CARLSON_TOL * An) { 
            break;
        }

        An = (An + lambda) * 0.25;
        xn = (xn + lambda) * 0.25;
        yn = (yn + lambda) * 0.25;
        zn = (zn + lambda) * 0.25;
        Q  *= 0.25;
        n4 *= 4.0; // 4^n for break or CARLSON_MAX_ITER
    }
    float X  = (A0 - x)/(n4 * An);
    float Y  = (A0 - y)/(n4 * An);
    float Z  = -(X+Y)/3.; 
    float XY = X*Y;
    float Z2 = Z*Z;
    float E2 = XY - 6.*Z2; 
    float E3 = (3.*XY - 8.*Z2)*Z;
    float E4 = 3.*(XY - Z2)*Z2;
    float E5 = XY*Z2*Z;
    float Expansion = (1. - 3./14.*E2 + E3/6. + 9./88.*E2*E2 - 3./22.*E4 - 9./52.*E2*E3 + 3./26.*E5);
    float RD = Expansion/(n4 * An*sqrt(An)) + 3.*Sum;
    return vec2(RD,n);
}

// Carlson's RF function [Carlson 1995, p.16]
float CarlsonRF(float x, float y, float z) { return CarlsonRFn(x,y,z).x; }

// Carlson's RD function [Carlson 1995, p.20]
float CarlsonRD(float x, float y, float z) { return CarlsonRDn(x,y,z).x; }

// Mathematica-style Incomplete Elliptic Integral of the First Kind, EllipticF(φ,m), with m=k² parameter.
// Computed in terms of Carlson's RF function [Carlson 1995, (4.5)].
float EllipticF(float phi, float m) {
    float  sinPhi = sin(phi);
    float  cosPhi = cos(phi);
    return sinPhi * CarlsonRF(cosPhi*cosPhi, 1.0 - m*sinPhi*sinPhi, 1.0); /// 1.0 vs cosPhi
}

// Mathematica-style Incomplete Elliptic Integral of the Second Kind, EllipticE(φ,m), with m=k² parameter.
// Computed in terms of Carlson's RF and RD functions [Carlson 1995, (4.6)].
float EllipticE(float phi, float m) {
    float sinPhi  = sin(phi);
    float  cosPhi = cos(phi);
    float cos2Phi = cosPhi * cosPhi;
    float sin2Phi = sinPhi * sinPhi;
    float sin3Phi = sin2Phi* sinPhi;
    return sinPhi * CarlsonRF(cos2Phi, 1.0 - m*sin2Phi, 1.0) 
           - (m*sin3Phi/3.0) * CarlsonRD(cos2Phi, 1.0 - m*sin2Phi, 1.0);
}

// Mathematica-style Incomplete Elliptic Integrals of both the First and Second Kinds, 
//   EllipticF(φ,m) and EllipticE(φ,m), respectively, with m=k² parameter.
//   Computed in terms of Carlson's RF & RD functions [Carlson 1995, (4.5,4.6)].
//   Faster than independent calls since shares a common CarlsonRF evaluation.
//   Also returns the max number of Carlson RD | RF iterations, n.
// @return vec3(F,E,n)
vec3 EllipticFEn(float phi, float m) {
    float sinPhi  = sin(phi);
    float cosPhi  = cos(phi);
    float sinPhi2 = sinPhi * sinPhi;
    float sinPhi3 = sinPhi2* sinPhi;
    float x       = cosPhi * cosPhi;
    float y       = 1.0  - m*sinPhi2;
    vec2  RFn     = CarlsonRFn(x, y, 1.0);// (RF,nRF)
    vec2  RDn     = CarlsonRDn(x, y, 1.0);// (RD,nRD)
    float n       = max(RFn.y, RDn.y);// max(nRF,nRD)
    float F       = sinPhi * RFn.x;
    float E       = F - (m*sinPhi3/3.0) * RDn.x;
    return vec3(F,E,n);
}

// Mathematica-style Incomplete Elliptic Integrals of both the First and Second Kinds, 
//   EllipticF(φ,m) and EllipticE(φ,m), respectively, with m=k² parameter.
//   Faster than independent calls since shares a common CarlsonRF evaluation.
// @return vec2(F,E)
vec2 EllipticFE(float phi, float m) {
  return EllipticFEn(phi,m).xy;
}
/*****************************************************************************/
/*** [END] CARLSON ITERATIONS AND ELLIPTIC FUNCTIONS *************************/
/*****************************************************************************/


/*****************************************************************************/
/*** [BEGIN] MAXWELL FLOW PROBLEM AND MONOTONE-PRECONDITIONED NEWTON SOLVER **/
/*****************************************************************************/

// Clamps |σ| ≤ (1-ε)π/2.
float mxwClampSigmaPosY(float sigma) {
  float sigmaMax = 0.99999 * PI_2;// avoid singularity 
  return clamp(sigma, -sigmaMax, sigmaMax); 
}

// Gradient of η_∞(p) 
vec2 mxwGradEtaInf(vec2 p) {
  float X  = p.x;
  float Y  = p.y; 
  float R2 = dot(p,p);
  float R4 = R2*R2;
  return vec2( 2.*X*Y/R4, 1. + 2.*Y*Y/R4 - 1./R2 );
}

// Signed η_∞ for point p=(X,Y) outside the unit circle.
float mxwEtaInf(vec2 p) {
  float X  = p.x;
  float Y  = p.y;   
  return Y - Y/(X*X + Y*Y);
}
// Signed η_∞ for point p=(X,Y) outside the unit circle.
float mxwEtaInf(float X, float Y) {
  return Y - Y/(X*X + Y*Y);
}
// Maxwell-flow angle σ((X,Y))∈(π,-π), where σ=0 corresponds to the +y axis.
// Input: p - Point outside the unit circle.
float mxwSigmaAt(vec2 p) { 

  float X=p.x;  float Y=p.y; 
  
  //if(abs(Y) < 0.0001)     return PI_2 * sign(X);  

  float R       = sqrt(X*X + Y*Y);
  float sigma   = asin(X/R);
  
  // REFLECT IF η<0: ensure π/2<|σ|<π
  sigma = (Y<0.0) ? ((sigma>=0.0) ? (PI-sigma) : -(PI+sigma)) : sigma; 
  return sigma;
}

// Maxwell-flow time at a point p=(X,Y) outside the unit circle. 
// Evaluated using elliptic functions and Carlson form iterations.
// Ill-conditioned near X-axis.
float mxwTimeAt(vec2 p) {

  float X = p.x;
  float Y = abs(p.y); // MirrorY: We're in the upper court, kids.

  float X2      = X*X;
  float Y2      = Y*Y;
  float R2      = X2 + Y2;
  float R       = sqrt(R2);
  float sigma   = asin(X/R); // σ∈[-π/2,π/2]
  sigma = mxwClampSigmaPosY(sigma); // Safety first. 
  
  float etaInf  = Y - Y/R2;
  float etaInf2 = etaInf*etaInf;
  float etaSq4  = etaInf2 + 4.0;
  float m       = 4.0/etaSq4;
  vec2  FE      = EllipticFE(sigma,m);
  float F       = FE.x;
  float E       = FE.y;
  float x       = ( etaSq4*E - (etaSq4-2.0)*F )/(2.0*sqrt(etaSq4));
  float t       = x - X;
  return t;
}

// Maxwell-flow time at a point given by (σ,η∞). 
// Ill-conditioned near X-axis.
// Assumption: |σ|<π/2  (Y>0)
float mxwTimeAtSigmaEta(float sigma, float eta) {

  sigma = mxwClampSigmaPosY(sigma); // Safety first.
  eta   = abs(eta); // MirrorY: We're in the upper court, kids.
 
  float eta2    = eta*eta;
  float etaSq4  = eta2 + 4.0;
  float m       = 4.0/etaSq4;
  vec2  FE      = EllipticFE(sigma,m);
  float F       = FE.x;
  float E       = FE.y;
  float x       = ( etaSq4*E - (etaSq4-2.0)*F )/(2.0*sqrt(etaSq4));
  
  float cosS   = cos(sigma);
  float Y      = 0.5*(eta + sqrt(eta2 + 4.0*cosS*cosS));
  float X      = Y * tan(sigma); // Ill-cond. near X axis: (Y→0)*(tan(σ→∓π/2)→∓∞) 
  float t      = x - X;
  return t;
}
// Maxwell-flow position given (σ,η∞).
// Badly behaved near X axis.
// Inputs:
//   sigma -  Angle σ((X,Y))∈(π,-π), where σ=0 corresponds to the +y axis.
//   eta   -  Solution curve value, η_∞. Signed η values allowed.
// Returns: Position p=(X,Y) outside the unit circle.
vec2 mxwPositionAtSigmaEta(float sigma, float eta) {
  
  float etaAbs = abs(eta);
  float eta2   = eta*eta;
  float cosS   = cos(sigma);
  float fug    = (eta2 + 4.0*cosS*cosS);// abs ∵ floating-point demons (!)
  float Y      = 0.5*(etaAbs + sqrt(eta2 + 4.0*cosS*cosS));// Y>0 for abs(eta)
  float sgnEta = sign(eta);
  float X      = sgnEta * Y * tan(sigma); // Ill-cond. near X axis: (Y→0)*(tan(σ→∓π/2)→∓∞)
  Y *= sgnEta;
  
  return vec2(X,Y);
}

// Maxwell arctan monotone preconditioner, M, and its derivative, D, at (t,η∞).
// Returns vec2(M,D).
vec2 mxwMD_arctan(float t, float eta) {//eta>0

  // REUSE S(eta):
  float eta2 = eta*eta;
  float S    = 0.5*( eta + (eta2 + 2.0)/sqrt(eta2 + 4.0) ); // Use abs(eta) to make it symmetric top/bottom
  
  float twoOverPI = 0.6366197723675813430;
  float M = +twoOverPI * atan(-t/S);
  float D = -twoOverPI / (S + t*t/S);

  return vec2(M, D);
}

// Maxwell tanha monotone preconditioner, M, and its derivative, D, at (t,η∞).
// Returns vec2(M,D).
vec2 mxwMD_tanha(float t, float eta) {//eta>0

  // REUSE S(eta):
  float eta2  = eta*eta;
  float S     = 0.5*( eta + (eta2 + 2.0)/sqrt(eta2 + 4.0) ); // Use abs(eta) to make it symmetric top/bottom
  
  // Optimized magic o((⊙﹏⊙))o numbers 
  float a     = 0.956764; 
  float s     = 1.05782; 
  float c     = 1.0 / (PI_2 * s * S); // scaling (slope adjustment)
  float T     = -c*t ; // Scaled time 
  float absT  = abs(T);
  float absTa = pow(absT, a);
  float tanha = sign(T) * tanh(absTa);
  float M     = tanha;

  // DERIV: 
  float coshTa = cosh(absTa);  
  float D      = -a*c* absTa/(absT+0.0001)/(coshTa*coshTa); // Regularize 1/|t| singularity 

  return vec2(M, D);
}

// Maxwell monotone preconditioner's magic α* value (for η≥0).
float mxwMD_alphaStar(float eta) {
  float  n      = eta;// ouch, lazy
  float  n2     = eta*eta;
  float  squirt = sqrt(n2+4.0);
  float  alpha  = 2.0*n*squirt / (n2 + n*squirt + 2.0);
  return alpha;
}
// Maxwell monotone preconditioner M, and its derivative, D, at specified (t,η∞).
// Returns vec2(M,D).
vec2 mxwMD(float t, float eta) {
  
  float  absEta   = abs(eta);
  vec2   arctanMD = mxwMD_arctan(t, absEta);
  vec2   tanhaMD  = mxwMD_tanha (t, absEta);
  float  alpha    = mxwMD_alphaStar(absEta);
  vec2   MD       = alpha*arctanMD + (1.0-alpha)*tanhaMD;
  return MD;
}

// The notorious t'(σ)=dt/dσ integrand of Maxwell's integral for t(σ).
float mxwTimeDerivSigmaEta(float sigma, float eta) {
  float n      = eta; // ooh, lazy.
  float n2     = eta*eta;
  float cosS   = cos(sigma);
  float cos2   = cosS*cosS;
  float squirt = sqrt(n2 + 4.0*cos2);
  return -0.5 * (n+squirt)*(n+squirt)/(cos2*squirt); 
}


/////////////////////////////////////////////////////////////////////////
/// Given Maxwell time tBar and η, solve for σ s.t. t(σ,η)=tBar.      ///
/// Uses Newton's method with monotonic preconditioning, to solve     ///
///               M(t(σ,η))=M(tBar)  ⇔  f(σ)=fBar                    ///
/////////////////////////////////////////////////////////////////////////
// NOTE: Works for all tBar and eta signs. 
//       Returns |σ|<π/2 for η>0.
//       Returns π/2<|σ|<π for η<0.
float mxwSigmaSolver(float tBar, float eta) {

  float etaAbs = abs(eta);

  // EVAL fBar: 
  vec2   Fbar = mxwMD(tBar, etaAbs); // sloth: don't need derivative, D
  float  fBar = Fbar.x;// fBar = M(tBar);  Range: (-1,1)
  
  ////////////////////////
  // NEWTON'S METHOD:   //
  ////////////////////////
    
  // INITIAL GUESS (straight line approximation)
  float sigma = fBar * PI_2; // <π/2
  sigma = mxwClampSigmaPosY(sigma); // Safety first
  
  for(int iter=0; iter<20; iter++) {// MD_arctan MD_axwell
    float t      = mxwTimeAtSigmaEta(sigma, etaAbs); 
    vec2  MD     = mxwMD(t, etaAbs);// NOTE: eta>0 enforced
    float f      = MD.x;
    float fDeriv = MD.y * mxwTimeDerivSigmaEta(sigma, etaAbs);
    float dSigma = -(f - fBar)/fDeriv; 
    sigma += dSigma; 
    sigma = mxwClampSigmaPosY(sigma); // Safety first 

    // ADAPTIVE NEWTON TOL: 
    float SIGMA_NEWTON_TOL = 0.0000002; // Newton solver tol for σ(t)  
    float tolExp = 5.0*smoothstep(0.01, 0.5, etaAbs); 
    SIGMA_NEWTON_TOL *= pow(2., tolExp); 
    if(etaAbs > 1.) SIGMA_NEWTON_TOL = 0.00001; 
    
    if(abs(dSigma) < PI_2 * SIGMA_NEWTON_TOL) break;
  }
  
  // REFLECT IF η<0: ensure π/2<|σ|<π
  if(eta<0.0) {
    if(sigma>=0.0) 
      sigma = PI - sigma; 
    else 
      sigma = -(PI + sigma);
  }
  
  return sigma;
}

// RAW MONOTONE-PRECONDITIONED NEWTON SOLVE FOR POSITION AT (t,η).
// POOR NEAR η≅0.
vec2 mxwPositionSolveAtTimeEta(float t, float eta) {
  eta = (eta!=0.0)  ? eta : 0.0001; // Please stay off the line folks.  
  if(abs(eta)<0.0001) eta = 0.0001 * sign(eta); 
  float sigma = mxwSigmaSolver(t, eta);    // RETURNS σ∈(π,-π). Bad for large |t|.
  vec2  p     = mxwPositionAtSigmaEta(sigma, eta); // POOR NEAR η≅0.
  return p;
}

// RAW MONOTONE-PRECONDITIONED NEWTON SOLVER FOR POSITION ADVECTED FOR DT TIME.
vec2 mxwAdvectPointRaw(vec2 p, float dt) {
  float  eta  = mxwEtaInf(p);
  float  t    = mxwTimeAt(p);// BUG: Huge values near eta~0
  float  tNew = t + dt;
  return mxwPositionSolveAtTimeEta(tNew, eta); // BUG: HUGE VALUES OF tNew near eta~0.
}

// Advects point through unit-cylinder-flow but transitions to "pure translation" outside a 
//    maximum T/Dist range to avoid distortion near x-axis. 
//    Uses Maxwell time monotone-preconditioned Newton advection solver (MTMPNAS).
// 
// Parameters: 
//   p       - Starting position.
//   dt      - Advection duration.
//   tCutoff - A positive time/distance, e.g., 20, beyond which to use the translation approximation.
// 
// Returns: 
//   Final advected position.
vec2 mxwAdvectPointTCutoff(vec2 p, float dt, float tCutoff) {

  float eta     = mxwEtaInf(p);
  float t       = mxwTimeAt(p);// BUG: Huge values near eta~0
  float tNew    = t + dt;
  
  vec2 pNew;
  if(abs(tNew)<tCutoff) {
    pNew = mxwPositionSolveAtTimeEta(tNew, eta); // BUG: HUGE VALUES OF tNew near η∞~0.
  }
  else {// Break advection into two steps: (1) near-field short-time σ(t) solve, and (2) far-field translation.
    float tSafe  = sign(tNew) * tCutoff;
    float tSlide = tNew - tSafe;
    pNew    = mxwPositionSolveAtTimeEta(tSafe, eta); 
    pNew.x -= tSlide;
  }
  return pNew;
}

// Advects p for time dt through flow around unit circle.
vec2 mxwAdvectPointUnpatched(vec2 p, float dt) {  
  return mxwAdvectPointTCutoff(p, dt, 20.);// Hard-coded TCutoff value
}

vec2 mxwAdvectPointUnitPatched(vec2 p, float dt, bool applyPatch) {
    
  float etaInf_p = mxwEtaInf(p); /// N.B.: Computer AFTER tine insertion.

  // ADVECT TEXTURE AROUND UNIT CYLINDER:
  vec2  pNew      = vec2(p);
  float etaMax    = 0.05; // patch size
  if(applyPatch && abs(etaInf_p) < etaMax) 
  {
    //vec2 a = vec2(0.);
    //vec2 b = vec2(dt, 0.);
    //pNew = p - b + rdSegment(p, b, a, 1.0);
       
    // EXTRAPOLATE INWARD ON y=0 PARAMETERIZATION'S SEAM:
    bool  inWedge = (acos(abs(normalize(p).x)) < 0.05);
    float xCrease = sign(dt) * (0.5 + abs(dt)); 
    bool  inPatchRegion = (inWedge && 
                              ( (dt<0. && (p.x>= 1.0 || p.x<xCrease)) || 
                                (dt>0. && (p.x<=-1.0 || p.x>xCrease)) ) );
    if(inPatchRegion) {
        
      // extrapolate from off-line y∈[-H,H]
      float H  = etaMax;
      float dy = (p.y<0. ? -H : H);
      vec2  pPerturb    = vec2(p.x, dy   ); 
      vec2  pPerturbNew = mxwAdvectPointUnpatched(pPerturb, dt); // [1st advection eval]
      vec2  u           = (pPerturbNew - pPerturb);

      // u.y SINGULARITY CORRECTION: Simple and fast linear model
      u.y *= abs(p.y)/H; 
            
      //{// Optional: CUBIC CORRECTION FOR u.y (meh): 
      //  float uy0 = u.y;  float uy1 = u2.y;
      //  float a   = (8.*uy0 - uy1)/(6.*H);
      //  float b   = (uy1 - 2.*uy0)/(6.*H*H*H);
      //  float y   = abs(p.y);
      //  float uy  = a*y + b *y*y*y;
      //  u.y = uy;
      //}
            
      // MINOR CURVATURE CORRECTION (noticeable around unit-cyl flow, but not cusp brush)
      // Avoid for cusp brush since uses an extra sample.
      if(false) {// FANCY u.x CURVATURE CORRECTION: 
        vec2 pPertur2     = vec2(p.x, dy*2.);
        vec2 pPertur2New  = mxwAdvectPointUnpatched(pPertur2, dt); // [2nd advection eval in patch]
        vec2 u2           = (pPertur2New - pPertur2); // for u.x curvature correction
            
        // PARABOLIC MODEL FOR u.x(y) CORRECTION: (call ux -> x) 
        //   x(y) = a y² + b            
        //   x1=x(h) & x2=x(2h)
        //   → a=(x2-x1)/(3h²)  &  b=(4 x1 - x2)/3
        { 
          float ux1 = u.x;
          float ux2 = u2.x;
          float a   = (ux2-ux1)/(3.*H*H);
          float b   = (4.*ux1 - ux2)/3.;
          float y   = p.y;
          u.x += (a*y*y + b - u.x); 
        }
      }

      pNew = p + u; 
      return pNew;
    }// PATCH END
  }// ELSE NOT IN PATCH REGION:
  
  // MONOTONE-PRECONDITIONED SOLVER:
  pNew = mxwAdvectPointUnpatched(p, dt); // [single advection eval]
  return pNew;
}

// Expands p to accommodate 2D incompressible insertion of a tine of radius r at the origin.
vec2 mxwApplyTineInsertionMap(vec2 p, float r) {
  if(dot(p,p)==0.) p = 0.000001*vec2(1.); // avoids R=0 and 0/0 result.
  
  float R = length(p); // current radius
  float S = sqrt(R*R + r*r);
  return S/R*p; 
}
// Contracts p to accommodate 2D incompressible removal of a tine of radius r at the origin.
vec2 mxwApplyTineRemovalMap(vec2 p, float r) {
  float R = length(p); // current radius
  float S = sqrt(max(0.f,R*R - r*r)); // avoid spurious NaNs
  return S/R*p;
}

// Maxwell unit-cylinder advection solver with tine insertion/removal and singularity patch.
vec2 mxwAdvectPointUnit(vec2 p, float dt, bool insertRemoveTine, bool applyPatch) 
{
    vec2 p0 = p;// initial position
    
    // SETUP CUSP PATCH:
    bool  cuspPatch = false;
    float cuspH     = min(0.02, 0.005*abs(dt));
    if(insertRemoveTine && applyPatch) {// PATCH THIS CUSP BRUSH: 
      //cuspH = min(cuspH, abs(p0.x));//wedge
      if(abs(p0.y)<cuspH && (sign(dt)*p0.x<0.0 || sign(dt)*p0.x > abs(dt)*0.8) ) {
        float dy = (p0.y<0. ? -cuspH : cuspH);
        //dy = 0.995*dy + 0.005*p0.y;// breaks-up constant-extrap. color banding 
        p.y = dy; // perturb compute location
        cuspPatch = true; // apply blend at end to u.y
      }
    }
    
    vec2 pPreCusp = p;// for computing displacement, u

    // INSERTION: INFLATE COORDS for R=1+epsRegularization circle: 
    float epsR = (applyPatch ? 0.0005 : 0.0); // pull out a little more paint when rd-removing tine
    p = (insertRemoveTine ? mxwApplyTineInsertionMap(p, 1.+epsR) : p); // rd end pos
   
    // ADVECTION AROUND PATCHED UNIT CYLINDER:
    vec2 pNew = mxwAdvectPointUnitPatched(p, dt, applyPatch);
      
    // IF REMOVE TINE, DEFLATE COORDS: 
    pNew = (insertRemoveTine ? mxwApplyTineRemovalMap(pNew, 1.0) : pNew); // rd start pos

    // PATCH CUSP:
    if(cuspPatch) { 
      vec2 u = pNew - pPreCusp; //p0;
      u.y *= abs(p0.y)/cuspH; 
      pNew = p0 + u; // filtered u.y
    }

    return pNew;
}

// Advect point p around a radius-R cylinder at the origin for flow distance L in -ve X direction.
vec2 mxwAdvectPointScaled(vec2 p, float L, float R, bool insertRemoveTine, bool applyPatch) 
{
  // SCALE TO UNIT-RADIUS WORLD:
  p /= R;
  float dt = L/R; // distance(=time) in unit-radius world.
  
  // ADVECT POINT:
  vec2 pNew = mxwAdvectPointUnit(p, dt, insertRemoveTine, applyPatch);
  
  // RETURN UNSCALED POINT:
  return R*pNew;
}
/*****************************************************************************/
/***  [END]  MAXWELL FLOW PROBLEM AND MONOTONE-PRECONDITIONED NEWTON SOLVER **/
/*****************************************************************************/


/*****************************************************************************/
/*** [BEGIN] REVERSE-DRIFT FIELD (RDF) IMPLEMENTATIONS                      **/
/*****************************************************************************/

// Line RDF: Matched series approximation to 1D drift.
// Input: height above flow line, and cylinder radius, r.
float rdLine1DS(float height, float r) {
  float  y     = height/r;
  float  dx    = 0.; //drift = 5.*r/(0.2 + pow(eta,3.));
  
  float eps = 0.002;
  y = sqrt(y*y + eps*eps); // y_eps
  
  float y2  = y *y; 
  float y4  = y2*y2;
  float y6  = y4*y2;
  float y8  = y6*y2;
  float y11 = y8*y2*y;
  
  if(y > 6.50416858646776)
  {
    dx = -((PI*(6615. - 1960.*y2 + 600.*y4 - 192.*y6 + 64.*y8))/(256.*y11));
  }
  else if (y > 0.8220844420096408)
  {
    float dy  = y - 2.3;
    float dy2 = dy*dy;
    float dy4 = dy2*dy2;
    dx = (-0.0413839 - 0.0937878*dy - 0.043355*dy2 - 0.0068946*dy2*dy + (1.77539e-6)*dy4 - (1.01973e-7)*dy4*dy) / (1.00000000000000 + 3.26035*(dy) + 3.66495*dy2 + 2.08615*dy2*dy + 0.665761*dy4 + 0.115772*dy4*dy + 0.00875686*dy4*dy2);
  }
  else
  {
    dx = -0.039720771 - 0.16369764*y2 + 0.0076619254*y4 - 0.00096477622*y6 + 0.00015811568*y8 
       + (0.50000000 + 0.093750000*y2 - 0.0073242188*y4 + 0.0010681152*y6 - 0.00018775463*y8)*log(y);
  }
  
  return 2.0 * r * dx; // UNDO UNIT-RADIUS XFORM & *2 for full drift.
}


// Reverse-drift field (RDF) for a line segment (a→b) computed with Mixwell solver.
// Tine insertion and removal is assumed, so the RDF can be evaluated everywhere.
// The Mixwell solver singularity is patched. 
// 
// Parameters:
//   p : Position to evaluate RDF
//   r : Tine radius
//   a : Line-segment start
//   b : Line-segment end
vec2 rdSegmentM(vec2 p, float r, vec2 a, vec2 b) {

  if(length(a-b)==0.) return vec2(0.);

  // Reverse of a→b motion is a←b: 
  // So shift b to the origin (start):
  p -= b;
  vec2  M = a - b; // Reverse motion vector 
  
  // Rotate to x-axis flow:
  float L = length(M); // assume dt=L/r>0 always  
  vec2  newXDir = normalize(M); 
  //vec2  newYDir = vec2(-newXDir.y, newXDir.x);  
  float cs = newXDir.x;
  float sn = newXDir.y;

  mat2  Q  = mat2(cs, -sn, +sn, cs); //rotation of X to B
  mat2  QT = mat2(cs, +sn, -sn, cs); //rotation of B to X
  
  if(dot(p,p)==0.) return M;// point at cusp tip.
  
  vec2 p0 = p;
  p = Q*p; // Rotate to x-axis flow orientation
  
  bool insertRemoveTine = true; 
  bool applyPatch       = true;
  vec2 pNew = mxwAdvectPointScaled(p, L, r, insertRemoveTine, applyPatch);
  pNew = QT*pNew; // Unrotate back to B flow orientation

  return (pNew - p0) + M; 
}

// 1D reverse drift for a line (e.g., x-axis) computed using Elliptic integrals (E).
// The singularity is regularized.
// 
// Parameters:
//   height - Height above flow centerline
//   r      - Cylinder radius
float rdLine1DE(float height, float r) 
{
  // Convert to unit-radius problem:
  float  y  = height/r; // = η∞
  float  y2 = y*y;      // = η∞²  
  
  // Rectify y and regularize singularity
  float eps = 0.002;
  y2 += eps*eps; // y2=y²+ε²
  y   = sqrt(y2); // y≥ε
  
  // Complete elliptic integrals: K[m]=F(π/2,m) and E[m]=E(π/2,m)
  float m  = -4.0/y2;
  vec2  FE = EllipticFE(PI_2, m);
  float K  = FE.x; // K[m]=F(π/2,m)
  float E  = FE.y; // E[m]=E(π/2,m)
    
  // 1D drift
  float  dx = ( y2*E - (y2+2.)*K ) / y;
  
  return r * dx; // Scale to r-radius problem
}

//vec2 rdLineE() {}

// cylFlowVelWorld: Velocity at point p in World frame for unit cylinder flow.
// Assumes unit radius cylinder at origin; unit translation speed along x; and v=(0,0) at ∞.
// Input:  vec2 p - 2D point. 
// Output: vec2 v - Velocity vector in World frame.
vec2 cylFlowVelWorld(vec2 p) {
  p = projectOutsideUnitDisk(p); // Safety first! (for timestepper)  
  float X2    = p.x * p.x;       // Precompute X²
  float Y2    = p.y * p.y;       // Precompute Y²
  float R2    = X2 + Y2;         // R² = X² + Y²
  float invR4 = 1.0 / (R2 * R2); // Inverse R⁴
  return vec2((X2 - Y2) * invR4,  2.0 * p.x * p.y * invR4);
}

// cylFlowVelBody: Velocity at point p in Body frame for unit cylinder flow.
// Assumes unit radius cylinder at origin; unit translation speed along x; and v=(-1,0) at ∞.
// Input: vec2 p - 2D point. Output: vec2 - Velocity vector in Body frame.
vec2 cylFlowVelBody(vec2 p) {
  return cylFlowVelWorld(p) - vec2(1.,0.);
}

// cylFlowVelWorld: Velocity at point p in World frame for unit cylinder flow.
// Assumes unit radius cylinder at origin; unit translation speed along x; and v=(0,0) at ∞.
// Input: vec2 p - 2D point. Unit velocity of cylinder, vc. 
// Output: vec2 - Velocity vector in World frame.
// NOTE: Matches cylFlowVelWorld(p) when vc=(1,0).
//vec2 cylFlowVelWorldArbDir(vec2 p, vec2 vc) {
//  vec2 d  = normalize(vc); // unit direction of cylinder motion  (SLOTH)
//  mat2 R  = mat2(d.x, -d.y, 
//                 d.y,  d.x); // Rotates (1,0) to   d
//  mat2 RT = transpose(R);    // Rotates   d   to (1,0)
//  
//  // PULL BACK TO REFERENCE FRAME (flow in -X direction)
//  vec2 pRef = R*p;
//  vec2 vRef = cylFlowVelWorld(pRef);
//  vec2 v    = RT*vRef; // PUSH FWD TO WORLD ORIENT 
//  return v;
//}
vec2 cylFlowVelWorldArbDir(vec2 p, vec2 vc) {
  vec2 d  = normalize(vc); // unit direction of cylinder motion  (SLOTH)
  //mat2 R  = mat2(d.x, -d.y, d.y,  d.x); // Rotates (1,0) to d
  //mat2 RT = transpose(R);               // Rotates   d   to (1,0)
  
  // PULL BACK TO REFERENCE FRAME (flow in -X direction)
  vec2 pRef = vec2(d.x*p.x + d.y*p.y, -d.y*p.x + d.x*p.y);       // R*p
  vec2 vRef = cylFlowVelWorld(pRef);
  // PUSH FWD TO WORLD ORIENT 
  return vec2(d.x*vRef.x - d.y*vRef.y, d.y*vRef.x + d.x*vRef.y); // RT*vRef 
}


// Verification: Brute-force time-stepped (TS) advection approximation to 1D drift. (Body frame calculation)
float rdLine1DTBody(float height, float r) {
  
  float y  = height/r; // UNIT-RADIUS TRANSFORM

  // RELEASE PARTICLE UPSTREAM (x=Xmax) and ADVECT UNTIL x<-Xmax
  // COMPARE DRIFT TO PURE TRANSLATING PARTICLE:
  float Xmax = 1000.; // big enough to avoid negative drift
  vec2  p0   = vec2(Xmax, y); // Particle init at (0,y) --> (pureTranslation-dx, ~y)
  vec2  p    = p0;
  int   i    = 0;
  float time = 0.0;
  while(p.x>-Xmax && i<3000) {
      float dt   = 0.01 * length(p);     // adaptive stepsize
      vec2  vp   = cylFlowVelBody(p);    // initial  velocity; (-1,0) at ∞
      vec2  pmid = p + vp*dt*0.5;        // midpoint position
      vec2  vmid = cylFlowVelBody(pmid); // midpoint velocity
      p    += vmid * dt;                 // midpoint method step
      time += dt;
      i++;
  }
  
  float  xPureTranslation = Xmax - time; 
  float  dx = -(p.x - xPureTranslation); // 1D drift
  return dx * r; // UNDO UNIT-RADIUS TRANSFORM
}

// Verification: Brute-force time-stepped advection approximation to 1D drift. (World frame calculation)
float rdLine1DTWorld(float height, float r) {
  
  float y  = height/r; // UNIT-RADIUS TRANSFORM

  // ADVECT PARTICLE at (0,y) AROUND CYLINDER MOVING FROM (x=-Xmax to +Xmax).
  // X DISPLACEMENT IS DRIFT.
  float Xmax = 1000.; // big enough to avoid negative drift
  vec2  p0   = vec2(0.,    y);// Particle init at (0,y) --> (-dx, ~y)
  vec2  c    = vec2(-Xmax,0.);// Cylinder position
  vec2  vc   = vec2(+1.0, 0.);// Cylinder velocity (constant for 1D drift calc)
  vec2  p    = p0;
  int   i    = 0;
  float time = 0.0;
  while(c.x<Xmax && i<3000) {
      vec2  q    = p - c;                 // relative particle position
      float dt   = 0.01 * length(q);      // adaptive stepsize
      vec2  vp   = cylFlowVelWorld(q);    // initial  velocity; (-1,0) at ∞
      vec2  pmid = p + vp*dt*0.5;         // midpoint position
      vec2  cmid = c + vc*dt*0.5;         // midpoint cylinder position
      vec2  qmid = pmid-cmid;             // midpoint relative particle position
      vec2  vmid = cylFlowVelWorld(qmid); // midpoint velocity
      p    += vmid * dt;                  // midpoint method step
      c    += vc   * dt;                  // advance cylinder
      time += dt;
      i++;
  }
  
  float  dx = -p.x; // 1D drift
  return dx * r; // UNDO UNIT-RADIUS TRANSFORM
}

// RDF at p for a circle(r) passing along an infinite line in (dir)ection passing through origin. 
vec2 rdLine(vec2 p, float r, vec2 dir) 
{
  dir = normalize(dir);
  vec2   n      = vec2(-dir.y, +dir.x);
  float  height = dot(p,n);
  vec2   rdf    = rdLine1DS(height,r) * dir;
  return rdf;
}

// Min distance from y to a tine of a comb with pitch hy, rooted at the origin.
float minCombDist(float y, float hy) {
  return hy * abs(fract(y/hy-0.5)-0.5);
}

// Nonpareil pattern.
vec2 rdNonpareil(vec2 p, float combR, vec2 combDir, float combGap, int nPasses) {
  vec2   dir     = normalize(combDir);
  vec2   n       = rot90(dir);
  float  y       = dot(p,n); 
  float  passGap = float(nPasses)*combGap; // wider spacing between passes for nicer falloff + overlap
  vec2   rdf     = vec2(0.);
  for(int k=0; k<nPasses; k++) {
    float  yOffset = float(k)*combGap;
    float  height = minCombDist(y+yOffset, passGap);
    rdf += rdLine1DS(height, combR) * dir;
  }
  return rdf;
}

// Nonpareil RDF with comb gap noise.
// Inputs:
//   p            : Evaluation point.
//   r            : Tine radius.
//   dir          : Combing direction.
//   combGap      : Spacing between tines.
//   combGapNoise : Amplitude of tine position variation (± this value).
vec2 rdNonpareilNoisy(vec2 p, float r, vec2 dir, float combGap, float combGapNoise) {
  dir = normalize(dir);
  vec2   n       = rot90(dir);
  float  y       = dot(p,n);
  float  dyMax   = r * RDSEGMENT_MASK_R_FACTOR + combGap; 
  int    dkMax   = int(ceil(dyMax/combGap));
  int    k0      = int(round(y/combGap));// closest (unpeturbed) tine.
  vec2   rdf     = vec2(0.);
  for(int k=k0-dkMax; k<=k0+dkMax; k++) {
    float noisek = 2.*iqhash(float(k))-1.;// ∈[-1,1)
    float yk     = combGap * float(k) + combGapNoise*noisek;
    ////if(iqhash(noisek*PI) > 0.12) // Optional tine dropout (skip for now)
    rdf += rdLine1DS(abs(y-yk),r) * dir;
  }
  return rdf;
}

// Gel-Git pattern.
vec2 rdGelGit(vec2 p, float combR, vec2 combDir, float combGap, int nPasses) {
  vec2   dir     = normalize(combDir);
  vec2   n       = rot90(dir);
  float  y       = dot(p,n); 
  float  passGap = float(nPasses)*combGap*2.0; // wider spacing between passes for nicer falloff + overlap
  vec2   rdf     = vec2(0.);
  // GIT ("left")
  for(int k=0; k<nPasses; k++) {
    float  yOffset = (0.5 + float(k))*combGap*2.0;
    float  height  = minCombDist(y+yOffset, passGap);
    rdf -= rdLine1DS(height, combR) * dir;
  }
  // GEL ("right")
  for(int k=0; k<nPasses; k++) {
    float  yOffset = float(k)*combGap*2.0;
    float  height  = minCombDist(y+yOffset, passGap);
    rdf += rdLine1DS(height, combR) * dir;
  }  
  return rdf;
}


// Returns A*sin(K*X+P) given W=(A,K,P).
float waveEval(float X, vec3 W) {   return W.x * sin(W.y * X + W.z);  }

// Returns unit vector tangent at X for f(X)=A*sin(K*X+P) given W=(A,K,P).
vec2 waveUnitTangent(float X, vec3 W) {   
   float Df = W.x * W.y * cos(W.y * X + W.z); // f'(X)
   vec2  T  = vec2(1.0, Df);
   return normalize(T);   
}

// Time-stepped advection approximation to 2D drift from a sine wave motion. (World frame calculation)
// Sine wave: y0 + amp*sin(K x + phase)
// Input: vec3 W=(A,K,P) describes the partial wave A*sin(K*X+P)
//        rightComb: true passes right (+x), false passes left (-x) direction.
vec2 rdSineT(vec2 p, float r, float waveY0, in vec3 W, bool rightComb) 
{
  float waveAmp   = W.x;  float waveK     = W.y;  float wavePhase = W.z;

  p.y     -= waveY0;  // TRANSLATE TO Y=0 CENTERLINE
  
  // UNIT-RADIUS TRANSFORM:
  p       /= r;            
  waveAmp /= r; 
  waveK   *= r;       // K'*x'=K*x invariance with x'=x/r implies that K'=K*r
  
  // TRANSLATE PARTICLE TO X=0 (move offset into phase):
  wavePhase += waveK*p.x;
  p.x = 0.0; // now X offset
  float y0 = p.y; // INIT POS: p=(0,y0)
  
  // WAVE PARAMS:
  W = vec3(waveAmp, waveK, wavePhase); // scaled wave params
  
  float rdir = (rightComb ? -1.0 : +1.0);// reverse x-dir for combing.

  // ADVECT PARTICLE at p AS CYLINDER MOVES ON SINEWAVE FROM (x=-Xmax to +Xmax).
  float Xmax = 50.; // big enough to avoid negative drift
  vec2  p0   = vec2(0.,   y0);      // Particle init at (0,y0) --> p 
  vec2  c    = vec2(-Xmax*rdir, 0.);// Cylinder position (bogus y value)
  vec2  vc;                         // Cylinder velocity (unit vector)
  int   i    = 0;
  float time = 0.0;
  while( (rdir*c.x < Xmax) && i<5000) {
      c.y = waveEval(c.x, W);            // correct cylinder y (project onto sine)
      vc  = waveUnitTangent(c.x,W) *rdir; // Unit velocity vector (vc.x > 0)
      vec2  q    = p - c;                // relative particle position
      float dt   = 0.05; // HQ:0.01   SQ:0.05  
      vec2  vp   = cylFlowVelWorldArbDir(q,vc); // particle  velocity
      vec2  pmid = p + vp*dt*0.5;        // midpoint position
      vec2  cmid = c + vc*dt*0.5;        // midpoint cylinder position
      vec2 vcmid = waveUnitTangent(cmid.x,W) *rdir;
      vec2  qmid = pmid - cmid;          // midpoint relative particle position
      vec2  vmid = cylFlowVelWorldArbDir(qmid,vcmid); // midpoint velocity
      
      // FWD EULER: 
      //p    += vp * dt;                 // position update
      //c    += vc * dt;                 // advance cylinder
      
      // MIDPOINT METHOD: 
      p +=  vmid * dt; 
      c += vcmid * dt;
      
      p  = projectOutsideUnitDisk(p-c) + c; // Avoid losing particles inside disk 
      
      time += dt;
      i++;
  }

  vec2   rdrift = p-p0; // reverse drift
  return rdrift * r;    // UNDO UNIT-RADIUS TRANSFORM
}

// DEBUG TEST: 1D drift computed using degenerate sine wave 2D drift. <VERIFIED!>
float debugRDrift1D_sine(float height, float r) {
  vec2   rdrift = rdSineT(vec2(0.,height), r, 0.0, vec3(0.0, 1.0, 0.0), true);
  return rdrift.x;
}

// Combs a→b (performs insert/remove flows at begin/end)
// Time-stepped implementation (T).
vec2 rdSegmentT(vec2 p, float r, vec2 a, vec2 b) { 

  // UNIT-RADIUS TRANSFORM:
  float invR = 1.0/r;
  p *= invR;
  a *= invR;
  b *= invR;
  
  // REVERSE COMB SETUP: b→a
  vec2  rdir = a - b;
  float L    = length(rdir); // units of r 
  
  float dist2Segment = sdSegment(p, a, b);
  
  // ADVECT PARTICLE at p AS CYLINDER MOVES FROM b to a.
  vec2  p0   = p;               // Particle init (USED TO GET RevDrift: p-p0)
  vec2  c    = b;               // Cylinder init
  vec2  vc   = normalize(rdir); // Cylinder unit velocity
  int   i    = 0;
  float time = 0.0;
    
  // IF REMOVE TINE, INFLATE COORDS:
  //p = applyTineInsertionMap(p, R ); // BODY FRAME
  p = b + mxwApplyTineInsertionMap(p-b, 1.); // WORLD FRAME
  
  // Reverse-advect p as cylinder moves from b→a:
  float tLeft = L;
  while(tLeft > 0.000) {
      vec2  q    = p - c;                // relative particle position
      
      float dt   = 0.2;//max(0.01, 0.10*min(1.0, length(p-b)));      
      dt *= max(0.05, dist2Segment); // adaptive stepsize (near segment)
      if(dt > tLeft) dt = tLeft;
      // TODO: should depend on L, r. 

      vec2  vp   = cylFlowVelWorldArbDir(q,vc); // particle  velocity
      vec2  pmid = p + vp*dt*0.5;        // midpoint position
      vec2  cmid = c + vc*dt*0.5;        // midpoint cylinder position
      vec2  qmid = pmid - cmid;          // midpoint relative particle position
      vec2  vmid = cylFlowVelWorldArbDir(qmid,vc); // midpoint velocity

      // FWD EULER: 
      //p    += vp * dt;                 // position update
      //c    += vc * dt;                 // advance cylinder

      // MIDPOINT METHOD: 
      p +=  vmid * dt;                   // position update
      c +=  vc   * dt;                   // advance cylinder
      
      p  = projectOutsideUnitDisk(p-c) + c; // Avoid losing particles inside disk 

      time  += dt;
      tLeft -= dt;
      i++;
  }
  
  p = a + mxwApplyTineRemovalMap(p-a, 1.); // WORLD FRAME; unit tine  

  vec2   rdrift = p-p0; // reverse drift
  return rdrift * r;    // UNDO UNIT-RADIUS TRANSFORM
}

// Combs a→b (performs insert/remove flows at begin/end).
vec2 rdSegment(vec2 p, float r, vec2 a, vec2 b)  
{
  // Optional: LOCAL MASK (zero beyond dMax ∝ r): 
  float d    = sdSegment(p,a,b);
  float dMax = RDSEGMENT_MASK_R_FACTOR * r; // ADJUST RDSEGMENT_MASK_R_FACTOR TO TASTE 
  if(d >= dMax) return vec2(0.);
  float mask = 1. - smoothstep(0.5*dMax, dMax, d); // blend-to-zero factor.
  
  return mask * rdSegmentM(p, r, a, b); 

  //if(d < 0.005f*r) // OPTIONAL: Timestep on-line singularities  
  //  return mask * rdSegmentT(p, r, a, b); // Time-stepped advection solver  
  //else 
  //  return mask * rdSegmentM(p, r, a, b); // Maxwell advection solver 
}

// Combs a→b (performs insert/remove flows at begin/end), with reverse option.
// @param reverse - Swaps a↔b.
vec2 rdSegmentRev(vec2 p, float r, vec2 a, vec2 b, bool reverse) {
  vec2 head = (reverse ? b : a);
  vec2 tail = (reverse ? a : b);
  return rdSegment(p, r, head, tail); 
}


vec2 rdTriangle(vec2 p, float r, vec2 p0, vec2 p1, vec2 p2) 
{
  vec2 pInit = p; // copy to compute rdrift
  
  vec2 P[4] = vec2[4] ( p0, p1, p2, p0 );
  
  float sdf    = sdTriangle(p, p0, p1, p2);
  float sdfMax = 5.*r; 
  if(sdf > sdfMax) return p-pInit;
  
  // Masking factor to avoid discontinuity:
  float masking = 1. - smoothstep(sdfMax/2., sdfMax, abs(sdf));

  if(false) {
      for(int i=2; i>=0; i--) { bool rev = false;
      //for(int i=0; i<3; i++) { bool rev = true;
        p += rdSegmentRev(p, r, P[i], P[i+1], rev); 
      }
  }
    
  // JAGGED CASE (as rdrift superposition - symmetric but nonphysical)
  if(true) {
      bool rev = false;
      vec2 u = vec2(0.);
      u += rdSegmentRev(p, r, P[0], P[1], rev); 
      u += rdSegmentRev(p, r, P[1], P[2], rev); 
      u += rdSegmentRev(p, r, P[2], P[0], rev); 
      p += u;
  }
  return (p - pInit)*masking;
}

// FOR ANALYSIS: Segment kernel (r=1) for L-length brush stroke from a=(0,0) to b=(L,0).
vec2 rdSegmentKernel(vec2 p, float L) {

  vec2  a = vec2(0., 0.); 
  vec2  b = vec2(L,0.);
  float r = 1.;
  
  // REVERSE COMB SETUP: b→a
  vec2  rdir = a - b;
  
  // ADVECT PARTICLE at p AS CYLINDER MOVES FROM b to a.
  vec2  p0   = p;               // Particle init (USED TO GET RevDrift: p-p0)
  vec2  c    = b;               // Cylinder init
  vec2  vc   = normalize(rdir); // Cylinder unit velocity
  
  // IF REMOVE TINE, INFLATE COORDS:
  //p = applyTineInsertionMap(p, R ); // BODY FRAME
  p = b + mxwApplyTineInsertionMap(p-b, 1.); // WORLD FRAME

  // Reverse-advect p as cylinder moves from b→a:
  vec2  q    = p - c;                // relative particle position
  float dt   = L;
  vec2  vp   = cylFlowVelWorldArbDir(q,vc); // particle  velocity

  // FWD EULER: 
  p    += vp * dt;                 // position update
  c    += vc * dt;                 // advance cylinder

  p = a + mxwApplyTineRemovalMap  (p-a, 1.); // unit tine

  vec2   rdrift = p-p0; // reverse drift
  return rdrift;
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
vec2 rdTriWave(vec2 p, float r, vec2 dir, float L, float A, bool broken, bool dashed) 
{ 
  vec2 p0 = p; // initial position for reverse drift calc (p-p0)
  dir = normalize(broken ? -dir : dir); // change direction so reversed rdSegments have same flow trend
    
  // Project p onto line --> c and get coords for p as (x,y)
  vec2  c    = dot(p,dir)*dir;
  float x    = dot(c,dir);
  float y    = length(p - c); // unsigned dist to line
  float segR = sqrt(A*A + L*L/16.);
  float R    = r * RDSEGMENT_MASK_R_FACTOR + segR;// Bounding radius of point w.r.t. qi
  

  float H  = L*0.5;
  float Rx = sqrt(R*R - y*y); // influence "radius" about x on line 
  int   iR = int(ceil ( (x+Rx)/H )); // max i
  int   iL = int(floor( (x-Rx)/H )); // min i

  vec2  vd = 0.5 *H *dir;
  vec2  vp = A*rot90(dir);

  for(int i=iR; i>=iL; i--) {// rev sweep
    float si = (abs(i)%2==0) ? -1. : +1.; // -1even | +1odd
    if(!dashed || (dashed && si<0.)) {
      vec2  qi = dir*H*float(i);
      vec2  ai = qi - vd + si*vp;
      vec2  bi = qi + vd - si*vp;
      p += rdSegmentRev(p, r, ai, bi, broken);
    }
  }
    
  return p - p0; // reverse drift displacement
}


vec2 rdTriWaveComb(vec2 p, float r, vec2 dir, float L, float A, bool broken, bool dashed, float combGap) 
{
  dir = normalize(dir);
  vec2  n   = rot90(dir);
  float y   = dot(p,n);
  float R   = A + r*RDSEGMENT_MASK_R_FACTOR; // 1D perp-influence radius of a wave centerline
  int   dk  = int(ceil (R/combGap));// Conservative range of wave indices influencing p 
  int   kp  = int(round(y/combGap));// Closest wave index (where origin wave is k=0)
  
  vec2  rdf = vec2(0.);
  for(int k=kp-dk; k<=kp+dk; k++) {// Sum nearby(p) wave RDFs:
    float  yk = float(k)*combGap;  // Perp offset of k'th centerline 
    vec2   pk = p - yk*n;          // Translate k'th wave to origin
    rdf += rdTriWave(pk, r, dir, L, A, broken, dashed); // Accumulate RDF of k'th triwave 
  }  
  return rdf;
}


/*****************************************************************************/
/*** [ END ] REVERSE-DRIFT FIELD (RDF) IMPLEMENTATIONS                      **/
/*****************************************************************************/

///END/////////////////////////////////////////////////////////////////
////  Mixwell Library Functions /// @author Doug L James, 2025 ////////
///////////////////////////////////////////////////////////////////////
