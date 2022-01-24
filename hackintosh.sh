#!/bin/bash

DEBUG=${DEBUG:-yes}
TMPDIR=/tmp/hackintosh

# Prepare tmp directory
if [ ! -d "$TMPDIR" ]; then
    mkdir -p $TMPDIR
fi

WORKDIR=$(realpath hackintosh)

# Debug or release
CHANNEL=RELEASE
CHANNEL_CAMEL=Release
if [ "$DEBUG" == "yes" ]; then
    CHANNEL=DEBUG
    CHANNEL_CAMEL=Debug
fi


# Functions
get_opencore_base() {
    if ! compgen -G "$TMPDIR/OpenCore*.zip" > /dev/null; then
        (cd $TMPDIR && curl -fSLOJ "https://github.com/acidanthera/OpenCorePkg/releases/download/0.7.7/OpenCore-0.7.7-${CHANNEL}.zip")
    fi

    if [ ! -d "$TMPDIR/OpenCore" ]; then
        (cd $TMPDIR ; unzip OpenCore*.zip -d OpenCore)
    fi

}

download_macos_recovery() {
    # Reference: https://dortania.github.io/OpenCore-Install-Guide/installer-guide/linux-install.html#downloading-macos
    if ! compgen -G "$TMPDIR/OpenCore/Utilities/macrecovery/*.dmg" > /dev/null; then
        (
            #   Big Sur (11)
            cd $TMPDIR/OpenCore/Utilities/macrecovery/
            python ./macrecovery.py -b Mac-42FD25EABCABB274 -m 00000000000000000 download
        )
    fi
}

download_extra() {
    filename=$(basename $1)
    (
        mkdir -p ${TMPDIR}/extras/
        cd ${TMPDIR}/extras
        if [ ! -f "$filename" ]; then
            curl -fSLO "$1"
        fi
    )
}

download_extra_zip() {
    download_extra $2

    filename=$(basename $2)
    # Extract zip
    if [ -d "${TMPDIR}/extras/$1" ]; then
        rm -rf "${TMPDIR}/extras/$1"
    fi
    unzip "${TMPDIR}/extras/$(basename $2)" -d "${TMPDIR}/extras/$1"
}

clone_extra() {
    project=$(basename $1)
    (
        mkdir -p ${TMPDIR}/extras/
        cd ${TMPDIR}/extras
        if [ ! -d "$project" ]; then
            git clone "$1"
        fi
    )
}

make_installer_base() {
    if [ -d "Installer" ]; then
        echo "Removing existing Installer directory."
        clean_installer
    fi

    OCDIR="${TMPDIR}/OpenCore/X64/EFI"

    (
        mkdir -p ${WORKDIR}/Installer
        cd ${WORKDIR}/Installer
        # recovery
        mkdir -p com.apple.recovery.boot
        cp ${TMPDIR}/OpenCore/Utilities/macrecovery/*.{dmg,chunklist} com.apple.recovery.boot/
        # EFI
        mkdir -p EFI
        cd EFI
        # BOOT folder
        cp -r ${OCDIR}/BOOT .
        mkdir -p OC/{ACPI,Drivers,Kexts,Tools}
        # OC/Drivers
        cp ${OCDIR}/OC/Drivers/OpenRuntime.efi OC/Drivers/
        cp -r ${OCDIR}/OC/Resources OC/
        cp ${OCDIR}/OC/Tools/OpenShell.efi OC/Tools/
        cp ${OCDIR}/OC/OpenCore.efi OC/
    )
}

make_installer_common() {
    (
        cd ${WORKDIR}/Installer

        # Drivers (*.efi)
        (
            cd EFI/OC/Drivers
            # HfsPlus
            if [ ! -f "HfsPlus.efi" ]; then
                echo "[EFI/OC/Drivers/HfsPlus.efi]"
                download_extra https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/HfsPlus.efi
                cp "${TMPDIR}/extras/HfsPlus.efi" .
            fi
        )
        # Kernel Extensions (*.kext)
        (
            cd EFI/OC/Kexts

            pwd


            echo "[EFI/OC/Kexts/VirtualSMC.kext]"
            download_extra_zip VirtualSMC https://github.com/acidanthera/VirtualSMC/releases/download/1.2.8/VirtualSMC-1.2.8-${CHANNEL}.zip
            cp -r "${TMPDIR}/extras/VirtualSMC/Kexts/VirtualSMC.kext" .
            cp -r "${TMPDIR}/extras/VirtualSMC/Kexts/SMCProcessor.kext" .
            cp -r "${TMPDIR}/extras/VirtualSMC/Kexts/SMCSuperIO.kext" .

            echo "[EFI/OC/Kexts/Lilu.kext]"
            download_extra_zip Lilu https://github.com/acidanthera/Lilu/releases/download/1.5.9/Lilu-1.5.9-${CHANNEL}.zip
            cp -r "${TMPDIR}/extras/Lilu/Lilu.kext" .

            echo "[EFI/OC/Kexts/WhateverGreen.kext]"
            download_extra_zip WhateverGreen https://github.com/acidanthera/WhateverGreen/releases/download/1.5.6/WhateverGreen-1.5.6-${CHANNEL}.zip
            cp -r "${TMPDIR}/extras/WhateverGreen/WhateverGreen.kext" .

            echo "[EFI/OC/Kexts/AppleALC.kext]"
            download_extra_zip AppleALC https://github.com/acidanthera/AppleALC/releases/download/1.6.8/AppleALC-1.6.8-${CHANNEL}.zip
            cp -r "${TMPDIR}/extras/AppleALC/AppleALC.kext" .
        )
    )
}

make_installer_z77x_ud5h() {
    # https://gist.github.com/al3xtjames/639a326c0330692b9a29
    #
    # GA-Z77X-UD5H (rev 1.0, rev 1.1)
    #     Audio: Realtek ALC898 Codec (see note)
    #     Ethernet: Intel 82579V GbE, Qualcomm Atheros AR8151 (rev 1.0) / AR8161 (rev 1.1) GbE
    #     SATA 2: Intel 7-Series Chipset (4x)
    #     SATA 3: Intel 7-Series Chipset (2x), Marvell 88SE9172 (3x)
    #     eSATA: Marvell 88SE9172 (1x)
    #     USB 2.0: Intel 7-Series Chipset (4x header, 2x rear)
    #     USB 3.0: Intel 7-Series Chipset (2x header), VIA VL810 (rev 1.0) / VL811 (rev 1.1) Hub (4x header, 4x rear)
    #     FireWire 400: VIA VT6308 (1x header, 1x rear)
    #     Note: rev 1.0 has broken front panel audio in Linux & OS X

    OCDIR="${TMPDIR}/OpenCore/X64/EFI"

    # Kernel Extensions (*.kext)
    (
        cd ${WORKDIR}/Installer/EFI/OC/Kexts

        echo "[EFI/OC/Kexts/IntelMausi.kext] - for Intel 82579V NIC"
        download_extra_zip IntelMausi https://github.com/acidanthera/IntelMausi/releases/download/1.0.7/IntelMausi-1.0.7-${CHANNEL}.zip
        cp -r "${TMPDIR}/extras/IntelMausi/IntelMausi.kext" .

        echo "[EFI/OC/Kexts/AtherosE2200Ethernet.kext] - for Qualcomm Atheros AR8151 v2.0 NIC"
        download_extra_zip AtherosE2200Ethernet https://github.com/Mieze/AtherosE2200Ethernet/releases/download/2.2.2/AtherosE2200Ethernet-V2.2.2.zip
        cp -r "${TMPDIR}/extras/AtherosE2200Ethernet/AtherosE2200Ethernet-V2.2.2/${CHANNEL_CAMEL}/AtherosE2200Ethernet.kext" .

        echo "[EFI/OC/Kexts/USBInjectAll.kext] - XHC, 7-series chipset"
        download_extra_zip USBInjectAll https://bitbucket.org/RehabMan/os-x-usb-inject-all/downloads/RehabMan-USBInjectAll-2018-1108.zip
        cp -r "${TMPDIR}/extras/USBInjectAll/${CHANNEL_CAMEL}/USBInjectAll.kext" .
    )

    # ACPI
    (
        cd ${WORKDIR}/Installer/EFI/OC/ACPI

        echo "[EFI/OC/ACPI/DSDT.aml] - Fixing Embedded Controller"
        download_extra https://raw.githubusercontent.com/Piker-Alpha/ssdtPRGen.sh/Beta/ssdtPRGen.sh
        download_extra https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-EC-DESKTOP.aml
        cp "${TMPDIR}/extras/SSDT-EC-DESKTOP.aml" .

        # echo "[EFI/OC/ACPI/DSDT.aml] - Generating DSDT for this PC"
        # clone_extra https://github.com/corpnewt/SSDTTime
        # # Select: 8 - Dump DSDT then 'q' quit
        # ${TMPDIR}/extras/SSDTTime/SSDTTime.command
        # cp ${TMPDIR}/extras/SSDTTime/Results/DSDT.aml .

        echo "[EFI/OC/ACPI/SSDT-PLUG-DRTNIA.aml] - Fixing Power Management"
        download_extra https://github.com/dortania/Getting-Started-With-ACPI/raw/master/extra-files/compiled/SSDT-PLUG-DRTNIA.aml
        cp ${TMPDIR}/extras/SSDT-PLUG-DRTNIA.aml .
    )

}

make_installer_wifi_intel() {
    (
        cd ${WORKDIR}/Installer/EFI/OC/Kexts

        # Intel Wifi card
        echo "[EFI/OC/Kexts/AirportItlwm.kext] - for Intel Wi-Fi 6 AX200"
        download_extra_zip AirportItlwm https://github.com/OpenIntelWireless/itlwm/releases/download/v2.1.0/AirportItlwm_v2.1.0_stable_BigSur.kext.zip
        cp -r "${TMPDIR}/extras/AirportItlwm/Big Sur/AirportItlwm.kext" .

        echo "[EFI/OC/Kexts/IntelBluetoothFirmware.kext] - for Intel Wi-Fi 6 AX200 (Bluetooth)"
        download_extra_zip IntelBluetoothFirmware https://github.com/OpenIntelWireless/IntelBluetoothFirmware/releases/download/v2.1.0/IntelBluetoothFirmware-v2.1.0.zip
        cp -r "${TMPDIR}/extras/IntelBluetoothFirmware/IntelBluetoothFirmware.kext" .
        cp -r "${TMPDIR}/extras/IntelBluetoothFirmware/IntelBluetoothInjector.kext" .
    )
}

make_installer_wifi_broadcom() {
    (
        cd ${WORKDIR}/Installer/EFI/OC/Kexts

        # Broadcom WiFi card
        echo "[EFI/OC/Kexts/AirportBrcmFixup.kext] - for Broadcom WiFi card"
        download_extra_zip AirportBrcmFixup https://github.com/acidanthera/AirportBrcmFixup/releases/download/2.1.3/AirportBrcmFixup-2.1.3-${CHANNEL}.zip
        cp -r "${TMPDIR}/extras/AirportBrcmFixup/AirportBrcmFixup.kext" .

        echo "[EFI/OC/Kexts/BrcmPatchRAM.kext] - for Broadcom WiFi card (Bluetooth)"
        download_extra_zip BrcmPatchRAM https://github.com/acidanthera/BrcmPatchRAM/releases/download/2.6.1/BrcmPatchRAM-2.6.1-${CHANNEL}.zip
        cp -r "${TMPDIR}/extras/BrcmPatchRAM/BrcmPatchRAM3.kext" .
        cp -r "${TMPDIR}/extras/BrcmPatchRAM/BrcmBluetoothInjector.kext" .
        cp -r "${TMPDIR}/extras/BrcmPatchRAM/BrcmFirmwareData.kext" .
    )
}

config_installer() {
    (
        cd ${WORKDIR}

        # SMBIOS
        if [ ! -f "SMBIOS" ]; then
            clone_extra https://github.com/corpnewt/GenSMBIOS
            ${TMPDIR}/extras/GenSMBIOS/GenSMBIOS.command
        else
            cat SMBIOS
        fi

        # config.plist
        if [ ! -f "config.plist.sample" ]; then
            cp ${TMPDIR}/OpenCore/Docs/Sample.plist ./config.plist.sample
        fi
        if [ ! -f "config.plist.patch" ]; then
            if [ ! -f "config.plist" ]; then
                cp config.plist.sample config.plist
            fi
            # Call ProperTree to edit config.plist
            clone_extra https://github.com/corpnewt/ProperTree
            # 1. Ctrl + Shift + R
            # 2. https://dortania.github.io/OpenCore-Install-Guide/config.plist/ivy-bridge.html#desktop-ivy-bridge
            ${TMPDIR}/extras/ProperTree/ProperTree.command "config.plist"

            # create patch
            diff -u config.plist.sample config.plist > config.plist.patch
        fi

        if [ ! -f "config.plist" ]; then
            cp config.plist.sample config.plist
            patch config.plist < config.plist.patch
        fi

        echo "[EFI/OC/config.plist]"
        cp config.plist ${WORKDIR}/Installer/EFI/OC/
    )
}

copy_installer_to_usb() {
    usb=$1
    if [ -z "$usb" ]; then
        echo "Usage: $0 copy <usb_path>"
        return
    fi

    rsync -av --delete ${WORKDIR}/Installer/ ${usb}/
}

show_installer() {
    tree -sh -L 5 ${WORKDIR}/Installer
}

clean_installer() {
    rm -rf ${WORKDIR}/Installer
}

clean() {
    rm -rf "$TMPDIR"
    clean_installer
}

usage() {
    echo "Usage: $0 oc-base"
}

main() {
    cmd=$1
    shift
    case "$cmd" in
        opencore)
            get_opencore_base
            download_macos_recovery
            ;;
        installer)
            make_installer_base
            make_installer_common
            make_installer_z77x_ud5h
            make_installer_wifi_intel
            config_installer
            ;;
        copy)
            copy_installer_to_usb "$@"
            ;;
        show)           show_installer  ;;
        clean)          clean           ;;
        *)              usage           ;;
    esac
}

# Entrypoint
main "$@"
