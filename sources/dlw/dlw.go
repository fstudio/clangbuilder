package main

import (
	"crypto/tls"
	"errors"
	"fmt"
	"io"
	"mime"
	"net"
	"net/http"
	stdurl "net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/fatih/color"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
	pb "gopkg.in/cheggaaa/pb.v1"
)

var (
	tr = &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client = &http.Client{Transport: tr}
)

// Header
var (
	AcceptRanges  = "Accept-Ranges"
	ContentLength = "Content-Length"
)

// Verbose
var (
	IsVerbose bool
)

// Verbose format
func Verbose(format string, a ...interface{}) {
	if IsVerbose {
		fmt.Fprintf(os.Stderr, format, a...)
	}
}

// FilterIP to string
func FilterIP(ips []net.IP) []string {
	vs := make([]string, 0, len(ips))
	for _, ip := range ips {
		vs = append(vs, ip.String())
	}
	return vs
}

// FatalCheck check
func FatalCheck(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "\x1b[31mERROR\x1b[0m: %v", err)
		panic(err)
	}
}

// ToFilename todo
func ToFilename(m, path string) string {
	_, p, _ := mime.ParseMediaType(m)
	filename := p["filename"]
	if len(filename) == 0 {
		filename = filepath.Base(path)
	}
	if filename == "." || filename == "/" {
		filename = "index.html"
	}
	return filename
}

// ToFilenameClear clean file
func ToFilenameClear(path string) string {
	p := filepath.Clean(path)
	if p == "." || p == "/" {
		return "index.html"
	}
	return p
}

/// Open unique file

// OpenUniqueFile open unique file
func OpenUniqueFile(path string) (*os.File, string, error) {
	folder := filepath.Dir(path)
	if _, err := os.Stat(folder); err != nil {
		if err = os.MkdirAll(folder, 0776); err != nil {
			return nil, "", err
		}
	}
	var upath string
	if _, err := os.Stat(path); err != nil {
		/// when file cannot  open say error
		if !os.IsNotExist(err) {
			return nil, "", err
		}
		upath = path
	} else {
		i := 1
		for ; i < 1000; i++ {
			upath = path + "." + strconv.Itoa(i)
			if _, err := os.Stat(upath); err != nil {
				if os.IsNotExist(err) {
					break
				}
			}
		}
		if i >= 1000 {
			return nil, "", errors.New("Cannot open file")
		}
	}
	file, err := os.OpenFile(upath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0664)
	if err != nil {
		return nil, "", err
	}
	return file, upath, nil
}

// LookupPath lookup
func LookupPath(url string) (string, error) {
	parsed, err := stdurl.Parse(url)
	if err != nil {
		return "", err
	}
	addrs, err := net.LookupIP(parsed.Host)
	if err != nil {
		return "", err
	}
	Verbose("Resolve Host %s: %s\n", parsed.Host, strings.Join(FilterIP(addrs), ","))
	return parsed.Path, nil
}

// Dlwdownload download to file
func Dlwdownload(url, savefile string) error {
	uripath, err := LookupPath(url)
	if err != nil {
		return err
	}
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("User-Agent", "Dlw/1.0")
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode > 300 {
		return errors.New(resp.Status)
	}
	var length int64
	clen := resp.Header.Get(ContentLength)
	if len(clen) != 0 {
		length, err = strconv.ParseInt(clen, 10, 64)
		if err != nil {
			return err
		}
	}
	// TO resolve file name
	if savefile == "" {
		savefile = ToFilename(resp.Header.Get("Content-Disposition"), uripath)
	} else {
		savefile = ToFilenameClear(savefile)
	}
	f, upath, err := OpenUniqueFile(savefile)
	if err != nil {
		return err
	}
	defer f.Close()
	Verbose("Save to %s\n", upath)
	bar := pb.New64(length).SetUnits(pb.U_BYTES).Prefix(color.YellowString(fmt.Sprintf("%s:", filepath.Base(upath))))
	barpool, err := pb.StartPool(bar)
	if err != nil {
		return err
	}
	defer barpool.Stop()

	writer := io.MultiWriter(f, bar)
	_, err = io.Copy(writer, resp.Body)
	if err != nil {
		if err != io.EOF {
			return err
		}
		bar.Finish()
	}
	return nil
}

// download util
func main() {
	verbose := kingpin.Flag("verbose", "Verbose mode.").Short('V').Bool()
	version := kingpin.Flag("version", "Print version and exit").Short('v').Bool()
	url := kingpin.Arg("url", "Download URL").String()
	dist := kingpin.Flag("output", "Output to file").Short('O').String()
	kingpin.Parse()
	if *version {
		fmt.Fprintf(os.Stderr, "dlw 1.0\n")
		os.Exit(0)
	}
	if len(*url) == 0 {
		fmt.Fprintf(os.Stderr, "no input url\n")
		os.Exit(1)
	}
	IsVerbose = *verbose
	var savefile string
	if dist != nil {
		savefile = *dist
	}
	if err := Dlwdownload(*url, savefile); err != nil {
		FatalCheck(err)
	}
}
