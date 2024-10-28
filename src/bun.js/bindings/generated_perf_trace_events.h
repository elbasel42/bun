// Generated with scripts/generate-perf-trace-events.sh
#define FOR_EACH_TRACE_EVENT(macro) \
  macro(Bundler.BindImportsToExports, 0) \
  macro(Bundler.CloneLinkerGraph, 1) \
  macro(Bundler.CreateNamespaceExports, 2) \
  macro(Bundler.FigureOutCommonJS, 3) \
  macro(Bundler.MatchImportsWithExports, 4) \
  macro(Bundler.ParseJS, 5) \
  macro(Bundler.ParseJSON, 6) \
  macro(Bundler.ParseTOML, 7) \
  macro(Bundler.ResolveExportStarStatements, 8) \
  macro(Bundler.Worker.create, 9) \
  macro(Bundler.WrapDependencies, 10) \
  macro(Bundler.breakOutputIntoPieces, 11) \
  macro(Bundler.cloneAST, 12) \
  macro(Bundler.computeChunks, 13) \
  macro(Bundler.findAllImportedPartsInJSOrder, 14) \
  macro(Bundler.findReachableFiles, 15) \
  macro(Bundler.generateChunksInParallel, 16) \
  macro(Bundler.generateCodeForFileInChunkCss, 17) \
  macro(Bundler.generateCodeForFileInChunkJS, 18) \
  macro(Bundler.generateIsolatedHash, 19) \
  macro(Bundler.generateSourceMapForChunk, 20) \
  macro(Bundler.getWorker, 21) \
  macro(Bundler.markFileLiveForTreeShaking, 22) \
  macro(Bundler.markFileReachableForCodeSplitting, 23) \
  macro(Bundler.onParseTaskComplete, 24) \
  macro(Bundler.postProcessJSChunk, 25) \
  macro(Bundler.readFile, 26) \
  macro(Bundler.renameSymbolsInChunk, 27) \
  macro(Bundler.scanImportsAndExports, 28) \
  macro(Bundler.treeShakingAndCodeSplitting, 29) \
  macro(Bundler.writeChunkToDisk, 30) \
  macro(Bundler.writeOutputFilesToDisk, 31) \
  macro(ExtractTarball.extract, 32) \
  macro(FolderResolver.readPackageJSONFromDisk.folder, 33) \
  macro(FolderResolver.readPackageJSONFromDisk.workspace, 34) \
  macro(JSBundler.addPlugin, 35) \
  macro(JSBundler.hasAnyMatches, 36) \
  macro(JSBundler.matchOnLoad, 37) \
  macro(JSBundler.matchOnResolve, 38) \
  macro(JSParser.analyze, 39) \
  macro(JSParser.parse, 40) \
  macro(JSParser.postvisit, 41) \
  macro(JSParser.visit, 42) \
  macro(JSPrinter.print, 43) \
  macro(JSPrinter.printWithSourceMap, 44) \
  macro(ModuleResolver.resolve, 45) \
  macro(PackageInstaller.install, 46) \
  macro(PackageInstaller.installPatch, 47) \
  macro(PackageManifest.Serializer.loadByFile, 48) \
  macro(PackageManifest.Serializer.save, 49) \
  macro(RuntimeTranspilerCache.fromFile, 50) \
  macro(RuntimeTranspilerCache.save, 51) \
  macro(RuntimeTranspilerCache.toFile, 52) \
  macro(StandaloneModuleGraph.serialize, 53) \
  macro(Symbols.followAll, 54) \
  macro(TestCommand.printCodeCoverageLCov, 55) \
  macro(TestCommand.printCodeCoverageLCovAndText, 56) \
  macro(TestCommand.printCodeCoverageText, 57) \
  // end
