/// Build-time entry point. Only imported by `build_runner`; never pulled into
/// the consuming app at runtime.
library;

import 'package:build/build.dart';

import 'src/url_aggregator_builder.dart';

Builder urlAggregatorBuilder(BuilderOptions options) => UrlAggregatorBuilder();
