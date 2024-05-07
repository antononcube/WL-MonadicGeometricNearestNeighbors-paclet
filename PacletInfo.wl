(* ::Package:: *)

PacletObject[
  <|
    "Name" -> "AntonAntonov/MonadicGeometricNearestNeighbors",
    "Description" -> "Software monad for Geometric Nearest Neighbors workflows",
    "Creator" -> "Anton Antonov",
    "License" -> "MIT",
    "PublisherID" -> "AntonAntonov",
    "Version" -> "1.0.4",
    "WolframVersion" -> "13.3+",
    "PrimaryContext" -> "AntonAntonov`MonadicGeometricNearestNeighbors`",
    "Extensions" -> {
      {
        "Kernel",
        "Root" -> "Kernel",
        "Context" -> {
          "AntonAntonov`MonadicGeometricNearestNeighbors`"
        },
        "Symbols" -> {
          "AntonAntonov`MonadicGeometricNearestNeighbors`$GNNMonFailure",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMon",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonAddToContext",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonAssignContextTo",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonAssignTo",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonAssignValueTo",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonBind",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonClassify",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonComputeAdjacencyMatrix",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonComputeProximityMatrix",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonComputeThresholds",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonContexts",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropAggregationFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropData",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropDistanceFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropFromContext",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropLowerThreshold",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropNearestFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropNearestIndexDistanceFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropNearestNeighborDistances",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropNumberOfNNs",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropRadius",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonDropUpperThreshold",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonEcho",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonEchoContext",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonEchoFunctionContext",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonEchoFunctionValue",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonEchoValue",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonFail",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonFindAnomalies",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonFindNearest",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonFold",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonGetData",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonIf",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonIfElse",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonIterate",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonMakeNearestFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonModifyContext",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonModule",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonNest",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonNestWhile",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonOption",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonPutContext",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonPutValue",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonRescale",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonRetrieveFromContext",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetAggregationFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetContext",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetData",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetDistanceFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetLowerThreshold",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetNearestFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetNearestIndexDistanceFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetNearestNeighborDistances",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetNumberOfNNs",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetRadius",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetUpperThreshold",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSetValue",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonSucceed",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeAggregationFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeContext",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeData",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeDistanceFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeLowerThreshold",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeNearestFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeNearestIndexDistanceFunction",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeNearestNeighborDistances",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeNumberOfNNs",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeRadius",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeUpperThreshold",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonTakeValue",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonUnit",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonUnitQ",
          "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMonWhen"
        }
      },
      {
        "Documentation",
        "Root" -> "Documentation",
        "Language" -> "English"
      }
    }
  |>
]
