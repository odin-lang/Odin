#!/usr/bin/env python3
"""
Builds `vendor/android/java/classes.dex` from the Java sources in this directory:

	OdinActivity  the NativeActivity `odin bundle android` adds to every app
	NativeProxy   implements Java interfaces with Odin procedures; `proxy.odin` embeds the dex for it

Needs a JDK (javac) and the SDK's build-tools (d8) and platform (android.jar).

Usage:
	python vendor/android/java/_dex/build.py [--sdk <path/to/sdk>] [--jdk <path/to/jdk>] [--platform android-37.2]

The SDK and JDK default to ODIN_ANDROID_SDK and JAVA_HOME.
"""

import argparse
import glob
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT  = os.path.normpath(os.path.join(HERE, "..", "classes.dex"))

# Odin's minimum Android API level.
MIN_API_LEVEL = 29


def newest(directory):
	def version(name):
		return [int(p) if p.isdigit() else 0 for p in name.replace("-", ".").split(".")]
	names = [n for n in os.listdir(directory) if n[:1].isdigit()]
	if not names:
		sys.exit(f"error: nothing in {directory}")
	return os.path.join(directory, max(names, key=version))


def run(cmd, env):
	print(" ".join(cmd))
	subprocess.run(cmd, env=env, check=True)


def main():
	ap = argparse.ArgumentParser(description="Build vendor/android/java/classes.dex.")
	ap.add_argument("--sdk", default=os.environ.get("ODIN_ANDROID_SDK"), help="SDK root (default: $ODIN_ANDROID_SDK)")
	ap.add_argument("--jdk", default=os.environ.get("JAVA_HOME"), help="JDK root (default: $JAVA_HOME)")
	ap.add_argument("--platform", default="android-37.2", help="platform directory under <sdk>/platforms")
	args = ap.parse_args()
	if not args.sdk or not args.jdk:
		sys.exit("error: pass --sdk and --jdk, or set ODIN_ANDROID_SDK and JAVA_HOME")

	windows     = os.name == "nt"
	android_jar = os.path.join(args.sdk, "platforms", args.platform, "android.jar")
	build_tools = newest(os.path.join(args.sdk, "build-tools"))
	javac       = os.path.join(args.jdk, "bin", "javac.exe" if windows else "javac")
	d8          = os.path.join(build_tools, "d8.bat" if windows else "d8")

	env = dict(os.environ)
	env["JAVA_HOME"] = args.jdk
	env["PATH"] = os.path.join(args.jdk, "bin") + os.pathsep + env.get("PATH", "")

	with tempfile.TemporaryDirectory() as tmp:
		classes = os.path.join(tmp, "classes")
		sources = sorted(glob.glob(os.path.join(HERE, "*.java")))
		run([javac, "--release", "11", "-Xlint:all", "-Werror", "-classpath", android_jar, "-d", classes] + sources, env)

		class_files = sorted(glob.glob(os.path.join(classes, "**", "*.class"), recursive=True))
		run([d8, "--release", "--min-api", str(MIN_API_LEVEL), "--lib", android_jar, "--output", tmp] + class_files, env)
		shutil.copyfile(os.path.join(tmp, "classes.dex"), OUT)

	print(f"wrote {OUT} ({os.path.getsize(OUT)} bytes)")


if __name__ == "__main__":
	main()
