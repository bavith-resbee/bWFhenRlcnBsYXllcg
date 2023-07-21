package com.maazter.rn.player.datasource

import android.net.Uri
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DataSpec
import com.google.android.exoplayer2.upstream.TransferListener
import java.io.InputStream

class InputStreamDataSource(private val stream: InputStream): DataSource {
    private lateinit var spec: DataSpec

    override fun read(target: ByteArray, offset: Int, length: Int): Int {
        val bytesRead = stream.read(target, offset, length)
        return if (bytesRead < 0) {
            C.RESULT_END_OF_INPUT
        } else bytesRead
    }

    override fun addTransferListener(transferListener: TransferListener) {
    }

    override fun open(dataSpec: DataSpec): Long {
        spec = dataSpec;
        return C.LENGTH_UNSET.toLong()
    }

    override fun getUri(): Uri {
        return spec.uri
    }

    override fun close() {
    }
}
