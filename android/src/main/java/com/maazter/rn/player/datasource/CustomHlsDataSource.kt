package com.maazter.rn.player.datasource

import android.net.Uri
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DataSourceInputStream
import com.google.android.exoplayer2.upstream.DataSpec
import com.google.android.exoplayer2.upstream.TransferListener
import com.google.android.exoplayer2.util.Assertions
import com.google.android.exoplayer2.util.Log
import com.google.android.exoplayer2.util.Util
import com.iheartradio.m3u8.*
import com.iheartradio.m3u8.data.Playlist
import com.iheartradio.m3u8.data.TrackData
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream

class CustomHlsDataSource(factory: DataSource.Factory, private val key: ByteArray) : DataSource {

    private var dataSource: DataSource = factory.createDataSource()

    private val _customKeyUrl = "https://key.provider.custom/${key}/enc.key"

    override fun read(target: ByteArray, offset: Int, length: Int): Int {
        return dataSource.read(target, offset, length);
    }

    override fun open(dataSpec: DataSpec): Long {
        val url = dataSpec.uri.toString();
        Log.d("url", url)

        if (url == _customKeyUrl) {
            dataSource = InputStreamDataSource(ByteArrayInputStream(key))
        } else if (Util.inferContentType(dataSpec.uri) == C.TYPE_HLS) {
            val stream = DataSourceInputStream(dataSource, dataSpec)
            stream.open()
            dataSource = InputStreamDataSource(replaceKeyFileInManifest(stream, _customKeyUrl))
        }

        return dataSource.open(dataSpec)
    }

    override fun close() {
        dataSource.close()
    }

    override fun addTransferListener(transferListener: TransferListener) {
        Assertions.checkNotNull(transferListener);
        dataSource.addTransferListener(transferListener);
    }

    override fun getUri(): Uri? {
        return dataSource.uri
    }

    private fun replaceKeyFileInManifest(inputStream: InputStream, keyFile: String): InputStream {
        val parser = PlaylistParser(inputStream, Format.EXT_M3U, Encoding.UTF_8, ParsingMode.LENIENT)
        var playlist: Playlist = parser.parse()
        if (playlist.hasMediaPlaylist()) {
            val tracks: MutableList<TrackData> = ArrayList(playlist.mediaPlaylist.tracks)
            val updatedTracks = tracks.map {
                it
                        .buildUpon()
                        .withEncryptionData(it.encryptionData
                                .buildUpon()
                                .withUri(keyFile)
                                .build())
                        .build()
            }

            playlist = playlist
                    .buildUpon()
                    .withMediaPlaylist(
                            playlist.mediaPlaylist
                                    .buildUpon()
                                    .withTracks(updatedTracks)
                                    .build()
                    )
                    .build()
        }

        val output = ByteArrayOutputStream()
        val writer = PlaylistWriter(output, Format.EXT_M3U, Encoding.UTF_8)
        writer.write(playlist)
        return ByteArrayInputStream(output.toByteArray())
    }
}
