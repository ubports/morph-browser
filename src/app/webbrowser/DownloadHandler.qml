import QtQuick 2.4
import Ubuntu.DownloadManager 1.2

DownloadManager {
    id: downloadManager

    onDownloadFinished: {
        downloadsModel.moveToDownloads(download.downloadId, path)
        downloadsModel.setComplete(download.downloadId, true)
    }

    onDownloadPaused: {
        downloadsModel.pauseDownload(download.downloadId)
    }

    onDownloadResumed: {
        downloadsModel.resumeDownload(download.downloadId)
    }

    onDownloadCanceled: {
        downloadsModel.cancelDownload(download.downloadId)
    }

    onErrorFound: {
        downloadsModel.setError(download.downloadId, download.errorMessage)
    }
}
