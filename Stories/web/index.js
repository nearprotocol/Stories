'use strict'

/* global Ipfs */
/* eslint-env browser */

const WebTorrent = require('webtorrent');

const torrentClient = new WebTorrent({ dht: true });

function uploadBlob(id, blobBase64) {
    const blob = new Buffer(blobBase64, 'base64');
    torrentClient.seed(blob, (torrent) => {
        console.log('uploadBlob torrent', torrent);
        _postMessage({ id, method: 'uploadBlob', response: { hash: torrent.infoHash, magnetURI: torrent.magnetURI } });
    });
}

function downloadBlob(id, hash) {
    torrentClient.add(hash, (torrent) => {
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
    contractName: 'studio-8h5y41o9o'
};
Cookies.set('fiddleConfig', config);

async function initNear() {
    const near = await nearlib.dev.connect();
    const nearUserId = nearlib.dev.myAccountId;
    return near.loadContract(config.contractName, {
        // NOTE: This configuration only needed while NEAR is still in development
        viewMethods: ["getRecentVideos"],
        changeMethods: ["postItem"],
        sender: nearUserId
    });
}
const initNearPromise = initNear();

function postItem(id, type, hash) {
    initNearPromise.then(contract => {
        contract.postItem({ type, hash }).then(() => {
            _postMessage({ id, method: 'postItem' });
        }, (error) => {
            _postMessage({ id, method: 'postItem', error: error && error.toString() });
        })
    });
}

function getRecentItems() {
    initNearPromise.then(contract => {
        contract.getRecentItems().then((items) => {
            _postMessage({ id, method: 'getRecentItems', response: items });
        }, (error) => {
            _postMessage({ id, method: 'getRecentItems', error: error && error.toString() });
        })
    }); 
}

Object.assign(window, { uploadBlob, postVideo })
