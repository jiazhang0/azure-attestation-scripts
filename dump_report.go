// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

// from https://raw.githubusercontent.com/microsoft/confidential-sidecar-containers/d933d0f4e3d5498f7ed9137189ab6a23ade15466/pkg/attest/snp.go

package main

import (
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
)

const (
	snpReportSize = 1184
)

type SNPAttestationReport struct {
	// version no. of this attestation report. Set to 1 for this specification.
	Version uint32 `json:"version"`
	// The guest SVN
	GuestSvn uint32 `json:"guest_svn"`
	// see table 8 - various settings
	Policy uint64 `json:"policy"`
	// as provided at launch    hex string of a 16-byte integer
	FamilyID string `json:"family_id"`
	// as provided at launch 	hex string of a 16-byte integer
	ImageID string `json:"image_id"`
	// the request VMPL for the attestation report
	VMPL          uint32 `json:"vmpl"`
	SignatureAlgo uint32 `json:"signature_algo"`
	// The install version of the firmware
	PlatformVersion uint64 `json:"platform_version"`
	// information about the platform see table 22
	PlatformInfo uint64 `json:"platform_info"`
	// 31 bits of reserved, must be zero, bottom bit indicates that the digest of the author key is present in AUTHOR_KEY_DIGEST. Set to the value of GCTX.AuthorKeyEn.
	AuthorKeyEn uint32 `json:"author_key_en"`
	// must be zero
	Reserved1 uint32 `json:"reserved1"`
	// Guest provided data.	64-byte
	ReportData string `json:"report_data"`
	// measurement calculated at launch 48-byte
	Measurement string `json:"measurement"`
	// data provided by the hypervisor at launch 32-byte
	HostData string `json:"host_data"`
	// SHA-384 digest of the ID public key that signed the ID block provided in SNP_LAUNCH_FINISH 48-byte
	IDKeyDigest string `json:"id_key_digest"`
	// SHA-384 digest of the Author public key that certified the ID key, if provided in SNP_LAUNCH_FINISH. Zeros if author_key_en is 1 (sounds backwards to me). 48-byte
	AuthorKeyDigest string `json:"author_key_digest"`
	// Report ID of this guest. 32-byte
	ReportID string `json:"report_id"`
	// Report ID of this guest's mmigration agent. 32-byte
	ReportIDMA string `json:"report_id_ma"`
	// Reported TCB version used to derive the VCEK that signed this report
	ReportedTCB uint64 `json:"reported_tcb"`
	// reserved 24-byte
	Reserved2 string `json:"reserved2"`
	// Identifier unique to the chip 64-byte
	ChipID string `json:"chip_id"`
	// The current commited SVN of the firware (version 2 report feature)
	CommittedSvn uint64 `json:"committed_svn"`
	// The current commited version of the firware
	CommittedVersion uint64 `json:"committed_version"`
	// The SVN that this guest was launched or migrated at
	LaunchSvn uint64 `json:"launch_svn"`
	// reserved 168-byte
	Reserved3 string `json:"reserved3"`
	// Signature of this attestation report. See table 23. 512-byte
	Signature string `json:"signature"`
}

func (r *SNPAttestationReport) DeserializeReport(report []uint8) error {

	if len(report) != snpReportSize {
		return fmt.Errorf("invalid snp report size")
	}

	r.Version = binary.LittleEndian.Uint32(report[0:4])
	r.GuestSvn = binary.LittleEndian.Uint32(report[4:8])
	r.Policy = binary.LittleEndian.Uint64(report[8:16])
	r.FamilyID = hex.EncodeToString(report[16:32])
	r.ImageID = hex.EncodeToString(report[32:48])
	r.VMPL = binary.LittleEndian.Uint32(report[48:52])
	r.SignatureAlgo = binary.LittleEndian.Uint32(report[52:56])
	r.PlatformVersion = binary.LittleEndian.Uint64(report[56:64])
	r.PlatformInfo = binary.LittleEndian.Uint64(report[64:72])
	r.AuthorKeyEn = binary.LittleEndian.Uint32(report[72:76])
	r.Reserved1 = binary.LittleEndian.Uint32(report[76:80])
	r.ReportData = hex.EncodeToString(report[80:144])
	r.Measurement = hex.EncodeToString(report[144:192])
	r.HostData = hex.EncodeToString(report[192:224])
	r.IDKeyDigest = hex.EncodeToString(report[224:272])
	r.AuthorKeyDigest = hex.EncodeToString(report[272:320])
	r.ReportID = hex.EncodeToString(report[320:352])
	r.ReportIDMA = hex.EncodeToString(report[352:384])
	r.ReportedTCB = binary.LittleEndian.Uint64(report[384:392])
	r.Reserved2 = hex.EncodeToString(report[392:416])
	r.ChipID = hex.EncodeToString(report[416:480])
	r.CommittedSvn = binary.LittleEndian.Uint64(report[480:488])
	r.CommittedVersion = binary.LittleEndian.Uint64(report[488:496])
	r.LaunchSvn = binary.LittleEndian.Uint64(report[496:504])
	r.Reserved3 = hex.EncodeToString(report[504:672])
	r.Signature = hex.EncodeToString(report[672:1184])

	return nil
}

func main() {
	var rawReportFile string

	flag.StringVar(&rawReportFile, "r", "", "Raw format of SNP Attestation Report")
	flag.Parse()

	if flag.NArg() != 0 || len(rawReportFile) == 0 {
		flag.Usage()
		os.Exit(1)
	}

	rawReportBytes, err := ioutil.ReadFile(rawReportFile)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error reading raw SNP Attestation Report file")
		os.Exit(1)
	}

	var report SNPAttestationReport
	err = report.DeserializeReport(rawReportBytes)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error deserializing raw SNP Attestation Report")
		os.Exit(1)
	}

	prettyJson, err := json.MarshalIndent(report, "", "    ")
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error marshaling SNPAttestationReport")
		os.Exit(1)
	}

	fmt.Println(string(prettyJson))
}
