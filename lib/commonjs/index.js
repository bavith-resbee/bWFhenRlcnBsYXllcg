"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.PlayerView = exports.Downloader = void 0;
exports.callFunction = callFunction;
exports.default = void 0;

var _reactNative = require("react-native");

const {
  MaazterDownloader
} = _reactNative.NativeModules;

const getViewManagerConfig = viewManagerName => {
  const version = _reactNative.NativeModules.PlatformConstants.reactNativeVersion.minor;

  if (version >= 58) {
    return _reactNative.UIManager.getViewManagerConfig(viewManagerName);
  } else {
    return _reactNative.UIManager[viewManagerName];
  }
};

function callFunction(ref, func) {
  let args = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : [];

  _reactNative.UIManager.dispatchViewManagerCommand((0, _reactNative.findNodeHandle)(ref), getViewManagerConfig("MaazterPlayerView").Commands[func], args);
}

const PlayerView = (0, _reactNative.requireNativeComponent)('MaazterPlayerView');
exports.PlayerView = PlayerView;
const MaazterDownloaderTyped = MaazterDownloader;
const events = {};
const EventMap = {
  downloadChange: "onDownloadChanged",
  downloadRemove: "onDownloadRemoved",
  idle: "onIdle"
};
const eventEmitter = new _reactNative.NativeEventEmitter(MaazterDownloader);
const Downloader = {
  add(contentId, contentUri, encKey, quality, data) {
    return MaazterDownloaderTyped.add(contentId, contentUri, encKey, quality, data);
  },

  remove(contentId) {
    return MaazterDownloaderTyped.remove(contentId);
  },

  pause(contentId, reason) {
    return MaazterDownloaderTyped.pause(contentId, reason);
  },

  resume(contentId) {
    return MaazterDownloaderTyped.resume(contentId);
  },

  pauseAll() {
    return MaazterDownloaderTyped.pauseAll();
  },

  resumeAll() {
    return MaazterDownloaderTyped.resumeAll();
  },

  listDownloads() {
    return MaazterDownloaderTyped.listDownloads();
  },

  getTracks(urlPath, encKey) {
    return MaazterDownloaderTyped.getTracks(urlPath, encKey);
  },

  addListener(name, callback) {
    name = EventMap[name];
    events[name] = events[name] || [];
    const listener = eventEmitter.addListener(name, callback);
    events[name].push([callback, listener]);
  },

  removeListener(name, callback) {
    name = EventMap[name];
    const event = events[name].find(listener => listener[0] === callback);
    event[1].remove();
    events[name] = events[name].filter(listener => listener[0] !== callback);
  }

};
exports.Downloader = Downloader;
var _default = PlayerView;
exports.default = _default;
//# sourceMappingURL=index.js.map