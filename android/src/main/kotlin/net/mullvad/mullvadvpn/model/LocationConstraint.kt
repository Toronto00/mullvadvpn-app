package net.mullvad.mullvadvpn.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

sealed class LocationConstraint(val code: Array<String>) : Parcelable {
    @Parcelize
    data class Country(var countryCode: String) :
        LocationConstraint(arrayOf(countryCode)), Parcelable

    @Parcelize
    data class City(var countryCode: String, var cityCode: String) :
        LocationConstraint(arrayOf(countryCode, cityCode)), Parcelable

    @Parcelize
    data class Hostname(var countryCode: String, var cityCode: String, var hostname: String) :
        LocationConstraint(arrayOf(countryCode, cityCode, hostname)), Parcelable
}
