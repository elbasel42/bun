import { describe, test } from "bun:test";
import { frameworkRouterInternals } from 'bun:internal-for-testing';
import { expect } from "bun:test";

const { parseRoutePattern } = frameworkRouterInternals;

const testRoutePattern = (style: string) => {
  // The 'expected' is a one-off string serialization that is only used for testing.
  // Params are serialized as ":param", catch all as ":*param", and optional catch all as ":*?param".
  const fn = (pattern:string, expected:string, kind: 'page' | 'layout' | 'extra'= 'page') => {
    test(`[${style}] should pass: ${JSON.stringify(pattern)})`, () => {
      const result = parseRoutePattern(style, pattern);
      expect(result.kind, 'expected route kind to match').toBe(kind);
      expect(result.pattern, 'expected route pattern to match').toBe(expected);
    }); 
  }
  fn.fails = (pattern: string, msg: string) => {
    test(`[${style}] should error: ${JSON.stringify(pattern)})`, () => {
      expect(() => parseRoutePattern(style, pattern)).toThrow(msg);
    });
  }
  return fn;
};

describe("route pattern parser", () => {
  const testPages = testRoutePattern('nextjs-pages-ui');
  testPages('/index.tsx', '', 'page');
  testPages('/_layout.tsx', '', 'layout');
  testPages('/subdir/index.tsx', '/subdir', 'page');
  testPages('/subdir/_layout.tsx', '/subdir', 'layout');
  testPages('/subdir/[page].tsx', '/subdir/:page', 'page');
  testPages('/[user]/posts.tsx', '/:user/posts', 'page');
  testPages('/[user]/_layout.tsx', '/:user', 'layout');
  testPages('/subdir/[page]/[other].tsx', '/subdir/:page/:other', 'page');
  testPages('/[page]/[other]/index.js', '/:page/:other', 'page');
  testPages('/[...data].js', '/:*data', 'page');
  testPages('/[[...data]].js', '/:*?data', 'page');
  testPages('/[...data]/index.tsx', '/:*data', 'page');
  testPages('/[[...data]]/index.jsx', '/:*?data', 'page');
  testPages('/hello/[...data]/index.tsx', '/hello/:*data', 'page');
  testPages('/hello/[[...data]]/index.jsx', '/hello/:*?data', 'page');
  testPages('/[...data]/_layout.tsx', '/:*data', 'layout');
  testPages('/[[...data]]/_layout.jsx', '/:*?data', 'layout');
  testPages('/hello/[...data]/_layout.tsx', '/hello/:*data', 'layout');
  testPages('/hello/[[...data]]/_layout.jsx', '/hello/:*?data', 'layout');
  // Parenthesis is the error location (column:length)
  testPages.fails('/subdir/[', 'Missing "]" to match this route parameter (8:1)');
  testPages.fails('/subdir/[a', 'Missing "]" to match this route parameter (8:2)');
  testPages.fails('/subdir/[page.tsx', 'Missing "]" to match this route parameter (8:9)');
  testPages.fails('/subdir/[]/hello', 'Parameter needs a name (8:2)');
  testPages.fails('/subdir/[.hello]-hello.tsx', 'Parameter name cannot start with \".\" (use \"...\" for catch-all) (8:8)');
  testPages.fails('/subdir/[..hello]-hello.tsx', 'Parameter name cannot start with \".\" (use \"...\" for catch-all) (8:9)');
  testPages.fails('/subdir/[...hello]-hello.tsx', 'Parameters must take up the entire file name (8:10)');
  testPages.fails('/subdir/[...hello]/bar.tsx', 'Catch-all parameter must be at the end of a route (8:10)');
  testPages.fails('/hello/[[optional_param]]/_layout.tsx', 'Optional parameters can only be catch-all (change to "[[...optional_param]]" or remove extra brackets) (7:18)');

  const testApp = testRoutePattern('nextjs-app-ui');
  testApp('/page.tsx', '', 'page');
  testApp('/layout.tsx', '', 'layout');
  testApp('/route/[param]/page.tsx', '/route/:param', 'page');
  testApp('/route/(group)/page.tsx', '/route/(group)', 'page');
  testApp('/route/[param]/not-found.tsx', '/route/:param', 'extra');
});