import 'allocator/arena';
export { memory };

import { contractContext, globalStorage, near } from './near';
import { Item } from './model.near';

// --- contract code goes below

export function postItem(item: Item): void {
  let id: u64 = globalStorage.getU64('lastId') + 1;
  globalStorage.setU64('lastId', id);
  globalStorage.setBytes('item:' + id.toString(), item.encode());
}

export function getRecentItems(): Item[] {
  // TODO: Range query
  return globalStorage.keys('item:').map<Item>((key: string, _1: i32, _2: String[]): Item => {
    return Item.decode(globalStorage.getBytes(key));
  });
}