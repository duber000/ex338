// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";
import LiveSocket from "phoenix_live_view";

// LiveView polyfills for IE11
import "mdn-polyfills/NodeList.prototype.forEach";
import "mdn-polyfills/Element.prototype.closest";
import "mdn-polyfills/Element.prototype.matches";
import "url-search-params-polyfill";
import "formdata-polyfill";

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

import "./header";
import "./filter_players";
import "./filter_trade_form";
import "./filter_players_list";
import "./confirm_submit";

let liveSocket = new LiveSocket("/live");
liveSocket.connect();

import StandingsChart from "./standings_chart.js";

let standingsChartElement = document.getElementById("standings-chart");
standingsChartElement && StandingsChart.buildChart();
