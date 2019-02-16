// Loads nearlib and this contract into window scope.

const initPromise = doInitContract();
async function doInitContract() {
  const config = await nearlib.dev.getConfig();
  console.log("nearConfig", config);
  
  window.near = await nearlib.dev.connect();
  
  window.contract = await near.loadContract(config.contractName, {
    viewMethods: ["getRecentItems"],
    changeMethods: ["postItem"],
    sender: nearlib.dev.myAccountId
  });
}

function sleep(time) {
  return new Promise(function (resolve, reject) {
    setTimeout(resolve, time);
  });
}

const trackers = ['wss://tracker.btorrent.xyz', 'wss://tracker.openwebtorrent.com', 'wss://tracker.fastcast.nz']
const rtcConfig = {
  'iceServers': [
    {
      'urls': 'stun:stun.l.google.com:19305'
    }
  ]
}
const torrentOpts = {
  announce: trackers
}
const trackerOpts = {
  announce: trackers,
  rtcConfig: rtcConfig
}

const torrentClient = new WebTorrent({ dht: true, tracker: trackerOpts });

async function loadVideos() {
  const items = await contract.getRecentItems();
  items.reverse();
  console.log('items', items);
  const container = document.querySelector('.container');
  for (let item of items) {
    console.log('loading: ', item.hash);
    let torrent = await new Promise((resolved, rejected) => {
      torrentClient.add(item.hash, torrentOpts, (torrent) => {
        resolved(torrent);
      });
    });
    let buffer = await new Promise((resolved, rejected) => {
      torrent.files[0].getBuffer((err, buffer) => {
        if (err) return rejected(err);
        resolved(buffer);
      });
    });
    console.log('loaded: ', item.hash);
    const url = URL.createObjectURL(new Blob([buffer]));
    if (item.type == "image") {
      const img = document.createElement('img');
      img.src = url;
      container.appendChild(img);
    } else {
      const video = document.createElement('video');
      video.src = url;
      container.appendChild(video);
    }
  }
}

initPromise
  .then(loadVideos)
  .catch(console.error);
