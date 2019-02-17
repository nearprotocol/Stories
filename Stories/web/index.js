'use strict'

/* global Ipfs */
/* eslint-env browser */

const WebTorrent = require('webtorrent');

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

function uploadBlob(id, blobBase64) {
    const blob = new Buffer(blobBase64, 'base64');
    torrentClient.seed(blob, (torrent) => {
        console.log('uploadBlob torrent', torrent);
        _postMessage({ id, method: 'uploadBlob', response: { hash: torrent.infoHash, magnetURI: torrent.magnetURI } });
    });
}

function downloadBlob(id, hash) {
    torrentClient.add(hash, torrentOpts, (torrent) => {
        console.log('downloadBlob torrent', torrent);
        torrent.files[0].getBuffer((error, buffer) => {
            _postMessage({ id, method: 'downloadBlob', error, response: buffer && buffer.toString('base64')});
        });
    });
}

// NOTE: Avoid clashing with window.postMessage
function _postMessage(message) {
    webkit.messageHandlers.callback.postMessage(message);
}

const config = {
    baseUrl: 'https://studio.nearprotocol.com/contract-api',
    nodeUrl: 'https://studio.nearprotocol.com/devnet',
    contractName: 'studio-edd5ohx8r'
};
Cookies.set('fiddleConfig', config);

async function initNear() {
    const near = await nearlib.dev.connect();
    const nearUserId = nearlib.dev.myAccountId;
    return near.loadContract(config.contractName, {
        // NOTE: This configuration only needed while NEAR is still in development
        viewMethods: ["getRecentItems"],
        changeMethods: ["postItem"],
        sender: nearUserId
    });
}
const initNearPromise = initNear();

function postItem(id, type, hash) {
    initNearPromise.then(contract => {
        contract.postItem({ item: { type, hash } }).then(() => {
            _postMessage({ id, method: 'postItem' });
        }, (error) => {
            _postMessage({ id, method: 'postItem', error: error && error.toString() });
        })
    });
}

function getRecentItems(id) {
    initNearPromise.then(contract => {
        contract.getRecentItems().then((items) => {
            _postMessage({ id, method: 'getRecentItems', response: items });
        }, (error) => {
            _postMessage({ id, method: 'getRecentItems', error: error && error.toString() });
        })
    }); 
}

Object.assign(window, { uploadBlob, downloadBlob, postItem, getRecentItems, torrentClient });

_postMessage({ method: 'loaded' });

const isLoaded = true;