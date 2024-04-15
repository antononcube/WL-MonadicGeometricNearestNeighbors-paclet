(* ::Package:: *)

(* Created by the Wolfram Language Plugin for IntelliJ, see http://wlplugin.halirutan.de/ *)

(* :Title: MonadicGeometricNearestNeighbors *)
(* :Context: AntonAntonov`MonadicGeometricNearestNeighbors` *)
(* :Author: Anton Antonov *)
(* :Date: 2019-09-22 *)

(* :Package Version: 0.9 *)
(* :Mathematica Version: 12.0 *)
(* :Copyright: (c) 2019 Anton Antonov *)
(* :Keywords: nearest neighbors, anomaly detection, outliers, monad *)
(* :Discussion:

   # In brief

   The primary motivation for making this Geometric Nearest Neighbors (GNN) software monad
   (GNNMon) is the implementation of a simple Nearest Neighbors (NN's) classifier that tells
   does a point belong to a set of points.

   That classification functionality can be also used to find outliers in a set points.

   # Usage example

    Block[{n = 30}, SeedRandom[343];
      points =
       Transpose[{RandomVariate[NormalDistribution[0, 5], n], RandomVariate[NormalDistribution[12, 3], n]}]
    ];

    gnnObj =
      GNNMonUnit[points]\[DoubleLongRightArrow]
       GNNMonMakeNearestFunction[DistanceFunction -> EuclideanDistance]\[DoubleLongRightArrow]
       GNNMonComputeThresholds[10, "AggregationFunction" -> Mean, "OutlierIdentifier" -> SPLUSQuartileIdentifierParameters];

    newPoints = {{-6, 2.5}, {4.5, 16}};

    doesNotBelong =
      gnnObj\[DoubleLongRightArrow]
       GNNMonFindAnomalies[newPoints, "UpperThresholdFactor" -> 1]\[DoubleLongRightArrow]
       GNNMonTakeValue

    (* {{-6, 2.5}} *)

    ListPlot[<|"Original points" -> points, "\"Does not belong\"" -> doesNotBelong, "New points" -> newPoints|>,
     PlotRange -> All,
     PlotStyle -> {{GrayLevel[0.6]}, {Pink, PointSize[0.022]}, {Blue, PointSize[0.01]}},
     ImageSize -> Large, PlotTheme -> "Detailed"]



   Anton Antonov
   Florida, USA
   2019-09-22
   2023-09-12 (made a paclet)

*)

(**************************************************************)
(* Package definition                                         *)
(**************************************************************)

BeginPackage["AntonAntonov`MonadicGeometricNearestNeighbors`"];
(* Exported symbols added here with SymbolName::usage *)

$GNNMonFailure::usage = "Failure symbol for GNNMon.";

GNNMonGetData::usage = "GNNMonGetData[] gets monad's points.";

GNNMonMakeNearestFunction::usage = "GNNMonMakeNearestFunction[opts] makes the Nearest function.";

GNNMonComputeThresholds::usage = "GNNMonComputeThresholds[ nTopNNs_Integer, aggrFunc_:Mean ] computes \
the proximity thresholds using nTopNNs nearest neighbors and aggregating with aggrFunc.";

GNNMonFindNearest::usage = "GNNMonFindNearest[ pnt_?VectorQ, nTopNNs_Integer ] finds nTopNNs of monad's points \
that are nearest to pnt.";

GNNMonClassify::usage = "GNNMonClassify[ pnts : { _?VectorQ | _?MatrixQ | Automatic }, opts ] classifies to True elements of pnts
that are considered close enough to monad's points.";

GNNMonFindAnomalies::usage = "GNNMonFindAnomalies[ pnts : { _?VectorQ | _?MatrixQ | Automatic }, opts ] finds anomalies \
of pnts according to monad's points.";

GNNMonRescale::usage = "GNNMonRescale non-monadic rescaling.";

GNNMonComputeProximityMatrix::usage = "GNNMonComputeProximityMatrix[n_Integer, opts] computes the proximity \
(similarity) matrix using the matrix context[\"nearestNeighborsDistances\"].";

GNNMonComputeAdjacencyMatrix::usage = "GNNMonComputeAdjacencyMatrix[ n_Integer | {n_Integer, r_?NumericQ}, opts] computes the adjacency \
(distance) matrix for specified number of nearest neighbors and max radius.";

PacletInstall["AntonAntonov/MonadMakers", AllowVersionUpdate -> False];
PacletInstall["AntonAntonov/SSparseMatrix", AllowVersionUpdate -> False];
PacletInstall["AntonAntonov/OutlierIdentifiers", AllowVersionUpdate -> False];
PacletInstall["AntonAntonov/DataReshapers", AllowVersionUpdate -> False];

Begin["`Private`"];

(* Needs["MathematicaForPredictionUtilities`"]; *)
Needs["AntonAntonov`MonadMakers`"];
Needs["AntonAntonov`OutlierIdentifiers`"];
Needs["AntonAntonov`SSparseMatrix`"];
Needs["AntonAntonov`DataReshapers`"];

(**************************************************************)
(* Generation                                                 *)
(**************************************************************)

(* Generate base functions of GNNMon monad (through StMon.) *)

GenerateStateMonadCode[ "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMon", "FailureSymbol" -> $GNNMonFailure, "StringContextNames" -> False ];

GenerateMonadAccessors[
  "AntonAntonov`MonadicGeometricNearestNeighbors`GNNMon",
  { "data",
    "nearestFunction", "nearestIndexDistanceFunction", "distanceFunction",
    "numberOfNNs", "nearestNeighborDistances",
    "aggregationFunction", "radius", "lowerThreshold", "UpperThreshold" },
  "FailureSymbol" -> $GNNMonFailure ];


(**************************************************************)
(* GetData                                                    *)
(**************************************************************)

Clear[DataAssociationQ];
DataAssociationQ[ data_ ] := AssociationQ[data] && MatrixQ[Values[data]];

ClearAll[GNNMonGetData];

SyntaxInformation[GNNMonGetData] = { "ArgumentsPattern" -> { } };

GNNMonGetData[$GNNMonFailure] := $GNNMonFailure;

GNNMonGetData[][xs_, context_Association] := GNNMonGetData[xs, context];

GNNMonGetData[xs_, context_Association] :=
    Block[{mat},

      Which[

        KeyExistsQ[context, "data"] && DataAssociationQ[context["data"]],
        GNNMonUnit[ context["data"], context ],

        MatrixQ[xs, NumericQ] && TrueQ[ Head[xs] === SparseArray ],
        GNNMonUnit[ AssociationThread[ Range @ Length @ xs, N @ Normal @ xs ], context ],

        TrueQ[ Head[xs] === Dataset ],
        (* DatasetToMatrix is implemented in the paclet "AntonAntnov/DataReshapers" *)
        mat =
            DatasetToMatrix[
              xs,
              "ExpectedColumnNames" -> Automatic,
              "FunctionName" -> "GNNMonGetData",
              "FailureSymbol" -> $GNNMonFailure
            ];

        If[ TrueQ[mat === $GNNMonFailure],
          Return[$GNNMonFailure]
        ];

        If[ AssociationQ @ Normal @ xs,
          GNNMonUnit[ AssociationThread[ Keys @ Normal @ xs, N @ mat], context],
          (*ELSE*)
          GNNMonUnit[ AssociationThread[ Range @ Length @ xs, N @ mat], context]
        ],

        MatrixQ[xs, NumericQ],
        GNNMonUnit[ AssociationThread[ Range @ Length @ xs, N @ xs ], context],

        SSparseMatrixQ[xs],
        GNNMonUnit[ AssociationThread[ RowNames[xs], Normal[N[SparseArray[xs]]] ], context],

        DataAssociationQ[ xs ],
        GNNMonUnit[xs, context],

        True,
        Echo["Cannot find data.", "GNNMonGetData:"];
        $GNNMonFailure
      ]

    ];

GNNMonGetData[___][xs_, context_Association] := $GNNMonFailure;


(**************************************************************)
(* Find distance from a point to matrix rows                  *)
(**************************************************************)
(* Non-monadic at this point. *)

Clear[GNNMonRescale];

GNNMonRescale[points_?MatrixQ] := GNNMonRescale[points, MinMax /@ Transpose[points]];

GNNMonRescale[points_?MatrixQ, mms_?MatrixQ] :=
    Block[{},
      Transpose@
          MapThread[Rescale[#1, #2, {0, 1}] &, {Transpose[points], mms}]
    ] /; Dimensions[points][[2]] == Dimensions[mms][[1]] && Dimensions[mms][[2]] == 2;


(**************************************************************)
(* Find distance from a point to matrix rows                  *)
(**************************************************************)

Clear[GNNMonMakeNearestFunction];

SyntaxInformation[GNNMonMakeNearestFunction] = { "ArgumentsPattern" -> { OptionsPattern[] } };

Options[GNNMonMakeNearestFunction] = { DistanceFunction -> EuclideanDistance };

GNNMonMakeNearestFunction[$GNNMonFailure] := $GNNMonFailure;

GNNMonMakeNearestFunction[xs_, context_Association] := GNNMonMakeNearestFunction[ Options[GNNMonMakeNearestFunction] ][xs, context];

GNNMonMakeNearestFunction[ opts : OptionsPattern[] ][xs_, context_Association] :=
    Block[{data, distFunc, nf, nfd},

      distFunc = OptionValue[ GNNMonMakeNearestFunction, DistanceFunction ];

      data = Fold[ GNNMonBind, GNNMonUnit[xs, context], { GNNMonGetData, GNNMonTakeValue } ];
      If[ TrueQ[ data === $GNNMonFailure ],
        Return[$GNNMonFailure]
      ];

      nf = Nearest[ data, DistanceFunction -> distFunc ];

      nfd = Nearest[ Values[data] -> {"Index", "Distance"}, DistanceFunction -> distFunc ];

      GNNMonUnit[ xs, Join[context, <| "data" -> data, "nearestFunction" -> nf, "nearestIndexDistanceFunction" -> nfd, "distanceFunction" -> distFunc |> ] ]
    ];

GNNMonMakeNearestFunction[___][xs_, context_Association] :=
    Block[{},
      Echo[
        "The expected signature is GNNMonMakeNearestFunction[ opts:OptionsPattern[] ].",
        "GNNMonMakeNearestFunction:"
      ];
      $GNNMonFailure
    ];


(**************************************************************)
(* Find distance from a point to matrix rows                  *)
(**************************************************************)

aOutlierFuncRules = <|
  "HampelIdentifierParameters" -> HampelIdentifierParameters,
  "HampelIdentifier" -> HampelIdentifierParameters,
  "Hampel" -> HampelIdentifierParameters,
  "QuartileIdentifierParameters" -> QuartileIdentifierParameters,
  "QuartileIdentifier" -> QuartileIdentifierParameters,
  "Quartile" -> QuartileIdentifierParameters,
  "SPLUSQuartileIdentifierParameters" -> SPLUSQuartileIdentifierParameters,
  "SPLUSQuartileIdentifier" -> SPLUSQuartileIdentifierParameters,
  "SPLUSQuartile" -> SPLUSQuartileIdentifierParameters
|>;

Clear[GNNMonComputeThresholds];

SyntaxInformation[GNNMonComputeThresholds] = { "ArgumentsPattern" -> { _, _., OptionsPattern[] } };

Options[GNNMonComputeThresholds] = { "OutlierIdentifier" -> HampelIdentifierParameters, "AggregationFunction" -> Mean };

GNNMonComputeThresholds[$GNNMonFailure] := $GNNMonFailure;

GNNMonComputeThresholds[xs_, context_Association] := $GNNMonFailure;

GNNMonComputeThresholds[ nTopNNs_Integer, opts : OptionsPattern[] ][xs_, context_Association] :=
    Block[{outFunc, aggrFunc, data, nfd, nns, means, ths, nnsMat},

      outFunc = OptionValue[ GNNMonComputeThresholds, "OutlierIdentifier" ] /. aOutlierFuncRules;
      aggrFunc = OptionValue[ GNNMonComputeThresholds, "AggregationFunction" ];

      data = GNNMonTakeData[xs, context];
      If[ TrueQ[ data === $GNNMonFailure ], Return[$GNNMonFailure] ];

      nfd = GNNMonTakeNearestIndexDistanceFunction[xs, context];
      If[ TrueQ[ nfd === $GNNMonFailure ], Return[$GNNMonFailure] ];

      (* Using nfd in order to speed-up the computations. *)
      nns = Map[ nfd[ #, nTopNNs + 1 ] &, Values[data] ];

      means =
          Association @
              MapIndexed[ Function[{v, ind}, ind[[1]] -> aggrFunc[ DeleteCases[ v[[All, 2]], {ind[[1]], _} ] ] ], nns];

      means = AssociationThread[ Keys[data][[ Keys[means] ]], Values[means] ];

      ths = outFunc[ N @ Values[means] ];

      nns = Join @@ MapIndexed[ Flatten /@ Thread[{#2[[1]], #1}] &, nns ];

      nns[[All, 1]] = Keys[ data ][[ nns[[All , 1]] ]];
      nns[[All, 2]] = Keys[ data ][[ nns[[All, 2]] ]];
      nnsMat = MakeSSparseMatrix[ nns ];

      GNNMonUnit[ ths,
        Join[context, <|
          "nearestNeighborDistances" -> nnsMat,
          "numberOfNNs" -> nTopNNs,
          "radius" -> aggrFunc[ Values[means] ],
          "aggregationFunction" -> aggrFunc,
          "lowerThreshold" -> ths[[1]],
          "upperThreshold" -> ths[[2]] |> ] ]
    ];

GNNMonComputeThresholds[___][xs_, context_Association] :=
    Block[{},
      Echo[
        "The expected signature is GNNMonComputeThresholds[ nTopNNs_Integer, opts:OptionsPattern[] ].",
        "GNNMonComputeThresholds:"
      ];
      $GNNMonFailure
    ];


(**************************************************************)
(* Find nearest points                                        *)
(**************************************************************)

Clear[GNNMonFindNearest];

SyntaxInformation[GNNMonFindNearest] = { "ArgumentsPattern" -> { _, _., OptionsPattern[] } };

GNNMonFindNearest[$GNNMonFailure] := $GNNMonFailure;

GNNMonFindNearest[xs_, context_Association] := $GNNMonFailure ;

GNNMonFindNearest[ pointSpec : (_?VectorQ | {_?VectorQ ..}), nTopNNs_Integer : 1, prop_String : "Values" ][xs_, context_Association] :=
    GNNMonFindNearest[ pointSpec, {nTopNNs, Infinity}, prop][xs, context];

GNNMonFindNearest[ pointSpec : (_?VectorQ | {_?VectorQ ..}), nnSpec : {_Integer, ( Infinity | _?NumericQ)}, prop_String : "Values" ][xs_, context_Association] :=
    Block[{data, nf, nns},

      data = Fold[ GNNMonBind, GNNMonUnit[xs, context], { GNNMonGetData, GNNMonTakeValue } ];
      If[ TrueQ[ data === $GNNMonFailure ], Return[$GNNMonFailure] ];

      nf = GNNMonTakeNearestFunction[xs, context];
      If[ TrueQ[ nf === $GNNMonFailure ], Return[$GNNMonFailure] ];

      Which[
        MemberQ[ { "indices", "indexes", "ids" }, ToLowerCase[prop]],
        nns = nf[pointSpec, nnSpec],

        MemberQ[ { "values", "points" }, ToLowerCase[prop]],
        nns = nf[pointSpec, nnSpec];
        nns = data[[ nns ]],

        ToLowerCase[prop] == "properties",
        Echo[ {"Indices", "Values", "Properties"}, "GNNMonFindNearest:"];
        nns = {"Indices", "Values", "Properties"},

        True,
        Echo["Unknown property.", "GNNMonFindNearest:"];
        Return[$GNNMonFailure]
      ];

      GNNMonUnit[ nns, context ]
    ];

GNNMonFindNearest[___][xs_, context_Association] :=
    Block[{},
      Echo[
        "The expected signature is GNNMonFindNearest[ point_?VectorQ, nTopNNs_Integer, prop_String : \"Values\" ].",
        "GNNMonFindNearest:"
      ];
      $GNNMonFailure
    ];



(**************************************************************)
(* Classify                                                   *)
(**************************************************************)

ClearAll[GNNMonClassify];

SyntaxInformation[GNNMonClassify] = { "ArgumentsPattern" -> { _., _., OptionsPattern[] } };

Options[GNNMonClassify] = { "UpperThresholdFactor" -> 1 };

GNNMonClassify[$GNNMonFailure] := $GNNMonFailure;

GNNMonClassify[xs_, context_Association] := GNNMonClassify[][xs, context];

GNNMonClassify[][xs_, context_Association] :=
    GNNMonClassify[ Automatic, "Decision", Options[GNNMonClassify] ][xs, context];

GNNMonClassify[ prop_String : "Decision", opts : OptionsPattern[] ][xs_, context_Association] :=
    GNNMonClassify[ Automatic, prop, opts][xs, context];

GNNMonClassify[ Automatic, prop_String : "Decision", opts : OptionsPattern[] ][xs_, context_Association] :=
    Block[{data},

      data = GNNMonTakeData[xs, context];
      If[ TrueQ[ data === $GNNMonFailure ], Return[$GNNMonFailure] ];

      GNNMonClassify[ data, prop, opts][xs, context]
    ];

GNNMonClassify[ point_?VectorQ, prop_String : "Decision", opts : OptionsPattern[] ][xs_, context_Association] :=
    GNNMonClassify[ <| 1 -> point |>, opts ][xs, context];

GNNMonClassify[ points_?MatrixQ, prop_String : "Decision", opts : OptionsPattern[] ][xs_, context_Association] :=
    GNNMonClassify[ AssociationThread[ Range[Length[points]] -> points ], prop, opts ][xs, context];

GNNMonClassify[ points_?DataAssociationQ, prop_String : "Decision", opts : OptionsPattern[] ][xs_, context_Association] :=
    Block[{factor, data, nfd, distFunc, nTopNNs, aggrFunc, upperThreshold, res, knownProperties},

      knownProperties = { "Decision", "Distances", "Probabilities", "Properties"};

      factor = OptionValue[GNNMonClassify, "UpperThresholdFactor" ];
      If[ ! ( NumberQ[ factor ] && factor > 0 ),
        Echo["The value of the option \"UpperThresholdFactor\" is expected to be a positive number.", "GNNMonClassify:"];
        Return[$GNNMonFailure]
      ];

      data = Fold[ GNNMonBind, GNNMonUnit[xs, context], { GNNMonGetData, GNNMonTakeValue } ];
      If[ TrueQ[ data === $GNNMonFailure ], Return[$GNNMonFailure] ];

      nfd = GNNMonTakeNearestIndexDistanceFunction[xs, context];
      If[ TrueQ[ nfd === $GNNMonFailure ], Return[$GNNMonFailure] ];

      distFunc = GNNMonTakeDistanceFunction[xs, context];
      If[ TrueQ[ distFunc === $GNNMonFailure ], Return[$GNNMonFailure] ];

      nTopNNs = GNNMonTakeNumberOfNNs[xs, context];
      If[ TrueQ[ nTopNNs === $GNNMonFailure ], Return[$GNNMonFailure] ];

      aggrFunc = GNNMonTakeAggregationFunction[xs, context];
      If[ TrueQ[ aggrFunc === $GNNMonFailure ], Return[$GNNMonFailure] ];

      upperThreshold = GNNMonTakeUpperThreshold[xs, context];
      If[ TrueQ[ upperThreshold === $GNNMonFailure ], Return[$GNNMonFailure] ];

      res = Map[ nfd[ #, nTopNNs ] &, Values[points] ];

      res = Association @
          MapIndexed[ Function[{v, ind}, ind[[1]] -> aggrFunc[ v[[All, 2]] ] ], res];

      res = AssociationThread[ Keys[points][[ Keys[res] ]], Values[res] ];

      Which[
        MemberQ[ ToLowerCase[{ "Decision" }], ToLowerCase[prop]],
        res = Map[ # <= upperThreshold * factor &, res ],

        MemberQ[ ToLowerCase[{ "Distances", "AggregatedDistances" }], ToLowerCase[prop]],
        Nothing,

        MemberQ[ ToLowerCase[{ "Probabilities" }], ToLowerCase[prop]],
        Echo["Probabilities of belonging is not implemented yet.", "GNNMonClassify:"];
        Nothing,

        ToLowerCase[prop] == "properties",
        Echo[ knownProperties, "GNNMonClassify:"];
        res = knownProperties,

        True,
        Echo["Unknown property. The second argument should be one of " <> ToString[knownProperties] <> ".",
          "GNNMonClassify:"];
        Return[$GNNMonFailure]
      ];

      GNNMonUnit[ res, context ]
    ];

GNNMonClassify[___][xs_, context_Association] :=
    Block[{},
      Echo[
        "The expected signature is GNNMonClassify[ points : ( _Association | _?VectorQ | _?MatrixQ | Automatic ), prop_String : \"Decision\" ].",
        "GNNMonClassify:"
      ];
      $GNNMonFailure
    ];


(**************************************************************)
(* Anomalies finder                                           *)
(**************************************************************)

ClearAll[GNNMonFindAnomalies];

SyntaxInformation[GNNMonFindAnomalies] = { "ArgumentsPattern" -> { _., OptionsPattern[] } };

Options[GNNMonFindAnomalies] = { "UpperThresholdFactor" -> 1 };

GNNMonFindAnomalies[$GNNMonFailure] := $GNNMonFailure;

GNNMonFindAnomalies[xs_, context_Association] := GNNMonFindAnomalies[][xs, context];

GNNMonFindAnomalies[][xs_, context_Association] := GNNMonFindAnomalies[ Options[GNNMonFindAnomalies] ][xs, context];

GNNMonFindAnomalies[ opts : OptionsPattern[] ][xs_, context_Association] :=
    GNNMonFindAnomalies[ Automatic, "Anomalies", opts ][xs, context];

GNNMonFindAnomalies[ points : ( _Association | _?VectorQ | _?MatrixQ | Automatic ), prop_String : "Anomalies", opts : OptionsPattern[] ][xs_, context_Association] :=
    Block[{res, knownProperties},

      knownProperties = {"Anomalies", "AnomalyPositions", "Decision", "Properties"};

      res = Fold[ GNNMonBind, GNNMonUnit[xs, context], {GNNMonClassify[points, "Decision", opts ], GNNMonTakeValue } ];
      If[ TrueQ[ res === $GNNMonFailure ], Return[$GNNMonFailure] ];

      Which[
        TrueQ[points === Automatic] && MemberQ[ ToLowerCase[{ "Anomalies" }], ToLowerCase[prop]],
        (* It assumed GNNMonClassify failed if !KeyExistsQ[context,"data"] *)
        res = Pick[Values[context["data"]], Not /@ Values[res]],

        MemberQ[ ToLowerCase[{ "Anomalies" }], ToLowerCase[prop]],
        res = Pick[points, Not /@ Values[res]],

        MemberQ[ ToLowerCase[{ "AnomalyPositions", "AnomalyKeys" }], ToLowerCase[prop]],
        res = Pick[Keys[res], Not /@ Values[res]],

        MemberQ[ ToLowerCase[{ "Decision" }], ToLowerCase[prop]],
        res = Not /@ res,

        ToLowerCase[prop] == "properties",
        Echo[ knownProperties, "GNNMonFindAnomalies:"];
        res = knownProperties,

        True,
        Echo["Unknown property. The second argument should be one of " <> ToString[knownProperties] <> ".",
          "GNNMonFindAnomalies:"];
        Return[$GNNMonFailure]
      ];

      GNNMonUnit[ res, context ]
    ];

GNNMonFindAnomalies[___][xs_, context_Association] :=
    Block[{},
      Echo[
        "The expected signature is GNNMonFindAnomalies[ points : ( _Association | _?VectorQ | _?MatrixQ | Automatic ), prop_String : \"Anomalies\" ].",
        "GNNMonFindAnomalies:"
      ];
      $GNNMonFailure
    ];


(**************************************************************)
(* Find proximity matrix                                      *)
(**************************************************************)

Clear[QuantileReplacementFunc];

QuantileReplacementFunc[qBoundaries : {_?NumberQ ...}] :=
    Block[{XXX,
      t = Partition[Join[{-\[Infinity]}, qBoundaries, {Infinity}], 2, 1]}, Function[
      Evaluate[ Piecewise[MapThread[{#2, #1[[1]] < XXX <= #1[[2]]} &, {t, Range[1, Length[t]]}]] /. {XXX -> #}]]
    ];


Clear[GNNMonComputeProximityMatrix];

SyntaxInformation[GNNMonComputeProximityMatrix] = { "ArgumentsPattern" -> { _, _., OptionsPattern[] } };

Options[GNNMonComputeProximityMatrix] = { "Rescale" -> True };

GNNMonComputeProximityMatrix[$GNNMonFailure] := $GNNMonFailure;

GNNMonComputeProximityMatrix[xs_, context_Association] := $GNNMonFailure;

GNNMonComputeProximityMatrix[ n_Integer, opts : OptionsPattern[] ][xs_, context_Association] :=
    Block[{rescaleQ, nnsMat, proxMat, smat, arules, qrFunc},

      rescaleQ = TrueQ[ OptionValue[GNNMonComputeProximityMatrix, "Rescale"] ];

      If[ n < 2,
        Echo["The first argument is expected to be an integer greater than 1.", "GNNMonComputeProximityMatrix:"];
        Return[$GNNMonFailure]
      ];

      nnsMat = GNNMonTakeNearestNeighborDistances[xs, context];
      If[ TrueQ[ nnsMat === $GNNMonFailure ], Return[$GNNMonFailure] ];

      qrFunc = QuantileReplacementFunc[ Quantile[SparseArray[nnsMat]["NonzeroValues"], Range[0, 1, 1 / (n - 1)]]];

      smat = SparseArray[nnsMat];

      arules = Most[ArrayRules[smat]];
      arules[[All, 2]] = Map[qrFunc, arules[[All, 2]]];

      If[ rescaleQ,
        arules[[All, 2]] = N @ Rescale[arules[[All, 2]], MinMax[arules[[All, 2]]], {1, 1 / Max[arules[[All, 2]]]}]
      ];

      proxMat = SparseArray[Join[arules, Table[{i, i} -> 1, {i, Dimensions[smat][[1]]}]], Dimensions[smat]];

      proxMat = ToSSparseMatrix[ proxMat, "RowNames" -> RowNames[nnsMat], "ColumnNames" -> ColumnNames[nnsMat]];

      GNNMonUnit[ proxMat, context ]
    ];

GNNMonComputeProximityMatrix[___][xs_, context_Association] :=
    Block[{},
      Echo[
        "The expected signature is GNNMonComputeProximityMatrix[ n_Integer, opts:OptionsPattern[] ].",
        "GNNMonComputeThresholds:"
      ];
      $GNNMonFailure
    ];


(**************************************************************)
(* Make adjacency matrix                                      *)
(**************************************************************)

Clear[GNNMonComputeAdjacencyMatrix];

SyntaxInformation[GNNMonComputeAdjacencyMatrix] = { "ArgumentsPattern" -> { _, OptionsPattern[] } };

Options[GNNMonComputeAdjacencyMatrix] = {"ImplicitValue" -> 0};

GNNMonComputeAdjacencyMatrix[$GNNMonFailure] := $GNNMonFailure;

GNNMonComputeAdjacencyMatrix[xs_, context_Association] := $GNNMonFailure;

GNNMonComputeAdjacencyMatrix[ nTopNNs_Integer, opts : OptionsPattern[]][xs_, context_Association] :=
    GNNMonComputeAdjacencyMatrix[{nTopNNs, Infinity}, opts][xs, context];

GNNMonComputeAdjacencyMatrix[ {nTopNNs_Integer, maxRadius : (_?NumericQ | Infinity) }, opts : OptionsPattern[]][xs_, context_Association] :=
    Block[{data, nns, nfd, nnsMat, iv},

      iv = OptionValue[GNNMonComputeAdjacencyMatrix, "ImplicitValue"];

      data = GNNMonTakeData[xs, context];
      If[ TrueQ[ data === $GNNMonFailure ], Return[$GNNMonFailure] ];

      nfd = GNNMonTakeNearestIndexDistanceFunction[xs, context];
      If[ TrueQ[ nfd === $GNNMonFailure ], Return[$GNNMonFailure] ];

      (* Using nfd in order to speed-up the computations. *)
      nns = Map[ nfd[ #, {nTopNNs + 1, maxRadius}] &, Values[data] ];

      If[ nTopNNs < 1,
        Echo[
          "The first argument is expected to specify number of nearest neighbors that is a positive integer.",
          "GNNMonComputeAdjacencyMatrix:"
        ];
        $GNNMonFailure
      ];

      (* Using nfd in order to speed-up the computations. *)
      nns = Map[ nfd[ #, {nTopNNs + 1, maxRadius} ] &, Values[data] ];

      nns = Join @@ MapIndexed[ Flatten /@ Thread[{#2[[1]], #1}] &, nns ];

      nns[[All, 1]] = Keys[ data ][[ nns[[All, 1]] ]];
      nns[[All, 2]] = Keys[ data ][[ nns[[All, 2]] ]];
      nnsMat = MakeSSparseMatrix[ nns, Automatic, iv];

      GNNMonUnit[ nnsMat, context ]
    ];

GNNMonComputeAdjacencyMatrix[___][xs_, context_Association] :=
    Block[{},
      Echo[
        "The expected signatures is GNNMonComputeAdjacencyMatrix[ n_Integer | {n_Integer, r_?NumericQ}, opts:OptionsPattern[] ].",
        "GNNMonComputeAdjacencyMatrix:"
      ];
      $GNNMonFailure
    ];

(*****Summary Box*****)
GNNMon /: MakeBoxes[obj_GNNMon, form : StandardForm] :=
    Block[{ctx = GNNMonBind[obj, GNNMonTakeContext]},
      BoxForm`ArrangeSummaryBox[
        GNNMon, gnnObj,
        None, (*the next argument is the always visible properties*)
        {
          BoxForm`SummaryItem@{"Dimensions: ", Dimensions[GNNMonBind[obj, GNNMonTakeData]]},
          BoxForm`SummaryItem@{"DistanceFunction: ", GNNMonBind[obj, GNNMonTakeContext]["distanceFunction"]},
          BoxForm`SummaryItem@{"Number of nearest neighbors: ", ctx["numberOfNNs"]},
          BoxForm`SummaryItem@{"Aggregation function: ", ctx["aggregationFunction"]}
        },
        {
          If[KeyExistsQ[ctx, "nearestFunction"],
            BoxForm`SummaryItem@{"NearestFunction: ", ctx["nearestFunction"]},
            Nothing
          ],
          If[KeyExistsQ[ctx, "radius"],
            BoxForm`SummaryItem@{"Radius: ", ctx["radius"]},
            Nothing
          ],
          If[KeyExistsQ[ctx, "lowerThreshold"],
            BoxForm`SummaryItem@{"Lower threshold: ", ctx["lowerThreshold"]},
            Nothing
          ],
          If[KeyExistsQ[ctx, "upperThreshold"],
            BoxForm`SummaryItem@{"Upper threshold: ", ctx["upperThreshold"]},
            Nothing
          ]
        },
        form]
    ];

End[]; (* `Private` *)

EndPackage[]
