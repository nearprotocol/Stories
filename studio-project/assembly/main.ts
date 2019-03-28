import 'allocator/arena';
export { memory };

import { storage, near } from './near';
import { Item } from './model.near';

// --- contract code goes below

export function postItem(item: Item): void {
  let id: u64 = storage.getU64('lastId') + 1;
  storage.setU64('lastId', id);
  storage.setBytes('item:' + id.toString(), item.encode());
}

export function getRecentItems(): Item[] {
  // TODO: Range query
  return storage.keys('item:').map<Item>((key: string, _1: i32, _2: String[]): Item => {
    return Item.decode(storage.getBytes(key));
  });
}