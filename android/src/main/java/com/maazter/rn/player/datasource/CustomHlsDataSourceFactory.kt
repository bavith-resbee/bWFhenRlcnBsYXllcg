package com.maazter.rn.player.datasource

import com.google.android.exoplayer2.upstream.DataSource

class CustomHlsDataSourceFactory(private val dataSource: DataSource.Factory, private val key: ByteArray) : DataSource.Factory {

    override fun createDataSource(): DataSource {
        return CustomHlsDataSource(dataSource, key)
    }
}
