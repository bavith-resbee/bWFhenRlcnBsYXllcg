import {
  requireNativeComponent,
  ViewStyle,
  findNodeHandle,
  UIManager,
  NativeModules,
  NativeEventEmitter
} from 'react-native';
const { MaazterDownloader } = NativeModules

type MaazterPlayerProps = {
  theme: string;
  buttonState: string;
  source: object;
  resizeMode: string;
  onCreate: () => void;
  onDestroy: () => void;
  onFullscreenChange: () => void;
  onPlayStateChange: () => void;
  onQualityChange: () => void;
  onPlaybackSpeedChange: () => void;
  onVideoSizeChange: () => void;
  onProgress: () => void;
  onBackClick: () => void;
  onPreviousClick: () => void;
  onNextClick: () => void;
  onSettingsClick: () => void;
  onError: () => void;
  style: ViewStyle;
  markers: object,
  playFrom: () => void
};

const getViewManagerConfig = (viewManagerName: string) => {
  const version = NativeModules.PlatformConstants.reactNativeVersion.minor;
  if (version >= 58) {
    return UIManager.getViewManagerConfig(viewManagerName);
  } else {
    return (UIManager as any)[viewManagerName];
  }
};

function callFunction(ref: any, func: string, args: any[] = []) {
  UIManager.dispatchViewManagerCommand(
    findNodeHandle(ref),
    getViewManagerConfig("MaazterPlayerView")
      .Commands[func],
    args
  );
}

interface DownloaderInterface {
  add(contentId: string, contentUri: string, encKey: string | null, quality: object, data: string | null): Promise<any>;
  remove(contentId: string): Promise<any>;
  pause(contentId: string, reason?: number): Promise<any>;
  resume(contentId: string): Promise<any>;
  pauseAll(): Promise<any>;
  resumeAll(): Promise<any>;
  listDownloads(): Promise<any>;
  getTracks(urlPath: string, encKey: string | null): Promise<any>;

  addListener(name: string, callback: Function): any;
  removeListener(name: string, callback: Function): any;
}

const PlayerView = requireNativeComponent<MaazterPlayerProps>('MaazterPlayerView');
const MaazterDownloaderTyped = MaazterDownloader as DownloaderInterface

const events: Record<string, Array<any>> = {};
const EventMap: Record<string, string> = {
  downloadChange: "onDownloadChanged",
  downloadRemove: "onDownloadRemoved",
  idle: "onIdle"
}

const eventEmitter = new NativeEventEmitter(MaazterDownloader);
const Downloader: DownloaderInterface = {
  add(contentId: string, contentUri: string, encKey: string | null, quality: object, data: string | null): Promise<any> {
    return MaazterDownloaderTyped.add(contentId, contentUri, encKey, quality, data)
  },
  remove(contentId: string): Promise<any> {
    return MaazterDownloaderTyped.remove(contentId)
  },
  pause(contentId: string, reason?: number): Promise<any> {
    return MaazterDownloaderTyped.pause(contentId, reason)
  },
  resume(contentId: string): Promise<any> {
    return MaazterDownloaderTyped.resume(contentId)
  },
  pauseAll(): Promise<any> {
    return MaazterDownloaderTyped.pauseAll()
  },
  resumeAll(): Promise<any> {
    return MaazterDownloaderTyped.resumeAll()
  },
  listDownloads(): Promise<any> {
    return MaazterDownloaderTyped.listDownloads()
  },
  getTracks(urlPath: string, encKey: string | null): Promise<any> {
    return MaazterDownloaderTyped.getTracks(urlPath, encKey)
  },

  addListener(name: string, callback: (...args: any[]) => any): any {
    name = EventMap[name]
    events[name] = events[name] || [];
    const listener: any = eventEmitter.addListener(name, callback);
    events[name].push([callback, listener]);
  },

  removeListener(name: string, callback: (...args: any[]) => any): any {
    name = EventMap[name]
    const event = events[name].find((listener => listener[0] === callback));
    event[1].remove()
    events[name] = events[name].filter((listener => listener[0] !== callback));
  }
}

export default PlayerView

export {
  Downloader,
  PlayerView,
  callFunction
}
