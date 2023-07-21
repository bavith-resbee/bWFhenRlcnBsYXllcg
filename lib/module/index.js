import { requireNativeComponent, findNodeHandle, UIManager, NativeModules, NativeEventEmitter } from 'react-native';
const {
  MaazterDownloader
} = NativeModules;

const getViewManagerConfig = viewManagerName => {
  const version = NativeModules.PlatformConstants.reactNativeVersion.minor;

  if (version >= 58) {
    return UIManager.getViewManagerConfig(viewManagerName);
  } else {
    return UIManager[viewManagerName];
  }
};

function callFunction(ref, func) {
  let args = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : [];
  UIManager.dispatchViewManagerCommand(findNodeHandle(ref), getViewManagerConfig("MaazterPlayerView").Commands[func], args);
}

const PlayerView = requireNativeComponent('MaazterPlayerView');
const MaazterDownloaderTyped = MaazterDownloader;
const events = {};
const EventMap = {
  downloadChange: "onDownloadChanged",
  downloadRemove: "onDownloadRemoved",
  idle: "onIdle"
};
const eventEmitter = new NativeEventEmitter(MaazterDownloader);
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
export default PlayerView;
export { Downloader, PlayerView, callFunction };
//# sourceMappingURL=index.js.map