'use strict'

/* global Ipfs */
/* eslint-env browser */

const WebTorrent = require('webtorrent');

const torrentClient = new WebTorrent({ dht: true });

function uploadBlob(id, blobBase64) {
    const blob = new Buffer(blobBase64, 'base64');
    torrentClient.seed(blob, (torrent) => {
        console.log('torrent', torrent);
        _postMessage({ id, method: 'uploadBlob', response: { hash: torrent.infoHash, magnetURI: torrent.magnetURI } });
    });
}

// NOTE: Avoid clashing with window.postMessage
function _postMessage(message) {
    webkit.messageHandlers.callback.postMessage(message);
}

const config = {
    baseUrl: 'https://studio.nearprotocol.com/contract-api',
    nodeUrl: 'https://studio.nearprotocol.com/devnet',
    contractName: 'studio-fc4db4c8j'
};
Cookies.set('fiddleConfig', config);

async function initNear() {
    const near = await nearlib.dev.connect();
    const nearUserId = nearlib.dev.myAccountId;
    return near.loadContract(config.contractName, {
        // NOTE: This configuration only needed while NEAR is still in development
        viewMethods: ["getLastVideos"],
        changeMethods: ["postVideo"],
        sender: nearUserId
    });
}
const initNearPromise = initNear();

function postVideo(id, hash) {
    initNearPromise.then(contract => {
        contract.postVideo({ hash }).then(() => {
            _postMessage({ id, method: 'postVideo' });
        }, (error) => {
            _postMessage({ id, method: 'postVideo', error: error && error.toString() });
        })
    });
}

Object.assign(window, { uploadBlob, postVideo })
