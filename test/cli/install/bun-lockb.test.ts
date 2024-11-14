import { spawn } from "bun";
import { expect, it } from "bun:test";
import { access, copyFile, writeFile } from "fs/promises";
import { bunExe, bunEnv as env, tmpdirSync } from "harness";
import { join } from "path";

it("should not print anything to stderr when running bun.lockb", async () => {
  const package_dir = tmpdirSync();

  // copy bar-0.0.2.tgz to package_dir
  await copyFile(join(__dirname, "bar-0.0.2.tgz"), join(package_dir, "bar-0.0.2.tgz"));

  // Create a simple package.json
  await writeFile(
    join(package_dir, "package.json"),
    JSON.stringify({
      name: "test-package",
      version: "1.0.0",
      dependencies: {
        "dummy-package": "file:./bar-0.0.2.tgz",
      },
    }),
  );

  // Run 'bun install' to generate the lockfile
  const installResult = spawn({
    cmd: [bunExe(), "install"],
    cwd: package_dir,
    env,
  });
  await installResult.exited;

  // Ensure the lockfile was created
  await access(join(package_dir, "bun.lockb"));

  // create a .env
  await writeFile(join(package_dir, ".env"), "FOO=bar");

  // Now test 'bun bun.lockb'
  const { stdout, stderr, exited } = spawn({
    cmd: [bunExe(), "bun.lockb"],
    cwd: package_dir,
    stdout: "pipe",
    stderr: "inherit",
    env,
  });

  const stdoutOutput = await new Response(stdout).text();
  expect(stdoutOutput).toBe(
    `# THIS IS AN AUTOGENERATED FILE. DO NOT EDIT THIS FILE DIRECTLY.\n# yarn lockfile v1\n# bun ./bun.lockb --hash: 8B7A1C2DA8966A48-f4830e6e283fffe9-DE5BD0E91FD9910F-f0bf88071b3f7ec9\n\n\n\"bar@file:./bar-0.0.2.tgz\":\n  version \"./bar-0.0.2.tgz\"\n  resolved \"./bar-0.0.2.tgz\"\n`,
  );

  const stderrOutput = await new Response(stderr).text();
  expect(stderrOutput).toBe("");

  expect(await exited).toBe(0);
});
