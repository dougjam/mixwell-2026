// Build-time reader for the released source files under public/code/.
//
// The site renders the SAME files it ships for download, so editing one on
// GitHub updates both the download and the highlighted page on the next deploy.
// Contents are inlined at build time (Vite ?raw), so there is no runtime file IO.

// Only text source extensions are globbed. Do NOT widen this to '*' — binary
// companions such as .hipnc live in the same folders and would be inlined into
// the bundle as (corrupt) strings.
const rawFiles = import.meta.glob<string>(
  '../../public/code/**/*.{osl,cl,glsl,hlsl,vert,frag,comp,h,hpp,c,cpp}',
  {
    query: '?raw',
    import: 'default',
    eager: true,
  }
);

/** Map of "code/osl/Name.osl" -> file contents. */
const byPath = new Map<string, string>();
for (const [key, contents] of Object.entries(rawFiles)) {
  // '../../public/code/osl/Foo.osl' -> 'code/osl/Foo.osl'
  const publicPath = key.replace(/^.*\/public\//, '');
  byPath.set(publicPath, contents);
}

/** Source text for a file under public/, e.g. getSource('code/osl/Foo.osl'). */
export function getSource(publicPath: string): string | undefined {
  return byPath.get(publicPath.replace(/^\/+/, ''));
}

/** Strip the leading SPDX/copyright block for display purposes (kept in downloads). */
export function fileSlug(fileName: string): string {
  return fileName.replace(/\.[^.]+$/, '');
}
