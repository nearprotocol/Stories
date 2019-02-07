import "allocator/arena";
export { memory };

import { contractContext, globalStorage, near } from "./near";

// --- contract code goes below

export function postVideo(hash: string): void {
  let id: u64 = globalStorage.getU64('lastId') + 1;
  globalStorage.setU64('lastId', id);
  globalStorage.setString('video:' + id.toString(), hash);
}

export function getLastVideos(): string[] {
  // TODO: Range query
  return globalStorage.keys('video:').map<string>((key: string, _1: i32, _2: string[]): string => {
    return globalStorage.getString(key);
  });
}