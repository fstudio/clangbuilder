/// Learn from https://github.com/p-ranav/indicators
#ifndef BAULK_INDICATORS_HPP
#define BAULK_INDICATORS_HPP
#include <bela/stdwriter.hpp>
#include <algorithm>
#include <atomic>
#include <cassert>
#include <chrono>
#include <cmath>
#include <thread>
#include <condition_variable>
#include <memory>
#include <type_traits>
#include <utility>
#include <vector>

namespace baulk {
[[maybe_unused]] constexpr uint64_t KB = 1024ULL;
[[maybe_unused]] constexpr uint64_t MB = KB * 1024;
[[maybe_unused]] constexpr uint64_t GB = MB * 1024;
[[maybe_unused]] constexpr uint64_t TB = GB * 1024;
[[maybe_unused]] constexpr uint32_t MAX_BARLENGTH = 256;
template <size_t N> void EncodeRate(wchar_t (&buf)[N], uint64_t x) {
  if (x >= TB) {
    _snwprintf_s(buf, N, L"%.2fT", (double)x / TB);
    return;
  }
  if (x >= GB) {
    _snwprintf_s(buf, N, L"%.2fG", (double)x / GB);
    return;
  }
  if (x >= MB) {
    _snwprintf_s(buf, N, L"%.2fM", (double)x / MB);
    return;
  }
  if (x > 10 * KB) {
    _snwprintf_s(buf, N, L"%.2fK", (double)x / KB);
    return;
  }
  _snwprintf_s(buf, N, L"%lldB", x);
}

enum ProgressState : uint32_t { Running = 33, Completed = 32, Fault = 31 };

class ProgressBar {
public:
  ProgressBar() = default;
  ProgressBar(const ProgressBar &) = delete;
  ProgressBar &operator=(const ProgressBar &) = delete;
  void Maximum(uint64_t mx) { maximum = mx; }
  void FileName(std::wstring_view fn) { filename = fn; }
  void Update(uint64_t value) { total = value; }
  void Execute() {
    worker = std::make_shared<std::thread>([this] {
      // Progress Loop
      space.resize(MAX_BARLENGTH + 4, L' ');
      scs.resize(MAX_BARLENGTH + 4, L'#');
      this->Loop();
    });
  }
  void Finish() {
    {
      std::lock_guard<std::mutex> lock(mtx);
      active = false;
    }
    cv.notify_all();
    worker->join();
  }
  void MarkFault() { state = ProgressState::Fault; }
  void MarkCompleted() { state = ProgressState::Completed; }

private:
  uint64_t maximum{0};
  uint64_t previous{0};
  mutable std::condition_variable cv;
  mutable std::mutex mtx;
  std::shared_ptr<std::thread> worker;
  std::atomic_uint64_t total{0};
  std::atomic_bool active{true};
  std::wstring space;
  std::wstring scs;
  std::wstring filename;
  std::atomic_uint32_t state{ProgressState::Running};
  uint32_t pos{0};
  uint32_t width{80};
  uint32_t flen{20};
  inline std::wstring_view MakeSpace(size_t n) {
    if (n > MAX_BARLENGTH) {
      return std::wstring_view{};
    }
    return std::wstring_view{space.data(), n};
  }
  inline std::wstring_view MakeRate(size_t n) {
    if (n > MAX_BARLENGTH) {
      return std::wstring_view{};
    }
    return std::wstring_view{scs.data(), n};
  }
  inline std::wstring_view MakeFileName() {
    if (filename.size() <= 19) {
      return filename;
    }
    return std::wstring_view{filename.data(), 19};
  }

  void Loop() {
    while (active) {
      {
        std::unique_lock lock(mtx);
        cv.wait_for(lock, std::chrono::milliseconds(100));
      }
      // --- draw progress bar
      Draw();
    }
    bela::FPrintF(stderr, L"\n");
  }
  void Draw() {
    auto w = bela::TerminalWidth();
    if (w != 0 && w <= MAX_BARLENGTH && w != width) {
      width = w;
      bela::FPrintF(stderr, L"\r\x1b[0m%s\x1b[0m",
                    MakeSpace((std::min)(w, MAX_BARLENGTH)));
    }
    if (width < 80) {
      width = 80;
    }
    // file.tar.gz 17%[###############>      ] 1024.00K 1024.00K/s
    auto barwidth = width - 50;
    wchar_t totalsuffix[64];
    wchar_t ratesuffix[64];
    auto total_ = static_cast<uint64_t>(total);
    pos++;
    if (pos == barwidth - 3) {
      pos = 0;
    }
    //' 1024.00K 1024.00K/s' 20
    auto delta = (total_ - previous) * 10; // cycle 50/1000 s
    previous = total_;
    EncodeRate(totalsuffix, total_);
    EncodeRate(ratesuffix, delta);
    if (maximum == 0) {
      // file.tar.gz  [ <=> ] 1024.00K 1024.00K/s
      constexpr std::wstring_view bounce = L"<=>";
      // '<=>'
      auto s0 = MakeSpace(pos);
      auto s1 = MakeSpace(barwidth - pos);
      bela::FPrintF(stderr, L"\r\x1b[01;%dm%s [%s%s%s] %s %s/s    \x1b[0m",
                    (uint32_t)state, MakeFileName(), s0, bounce, s1,
                    totalsuffix, ratesuffix);
      return;
    }
    //
    constexpr std::wstring_view half = L">";
    auto scale = total_ * 100 / maximum;
    auto progress = scale * barwidth / 100;
    auto ps = MakeRate(static_cast<size_t>(progress));
    auto sps = MakeSpace(static_cast<size_t>(barwidth - progress));
    bela::FPrintF(stderr, L"\r\x1b[01;%dm%s %d%% [%s%s] %s %s/s    \x1b[0m",
                  (uint32_t)state, MakeFileName(), scale, ps, sps, totalsuffix,
                  ratesuffix);
  }
};
} // namespace baulk

#endif