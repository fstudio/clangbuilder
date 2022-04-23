///
#ifndef CLANGBUILDER_COMUTILS_HPP
#define CLANGBUILDER_COMUTILS_HPP
#include <comdef.h>
#include <Sddl.h>
#include <Shlwapi.h>

namespace clangbuilder {
template <class T> class comptr {
public:
  comptr() { ptr = nullptr; }
  comptr(T *p) {
    ptr = p;
    if (ptr != nullptr)
      ptr->AddRef();
  }
  comptr(const comptr<T> &sptr) {
    ptr = sptr.ptr;
    if (ptr != nullptr)
      ptr->AddRef();
  }
  T **operator&() { return &ptr; }
  T *operator->() { return ptr; }
  T *operator=(T *p) {
    if (*this != p) {
      ptr = p;
      if (ptr != nullptr)
        ptr->AddRef();
    }
    return *this;
  }
  operator T *() const { return ptr; }
  template <class I> HRESULT QueryInterface(REFCLSID rclsid, I **pp) {
    if (pp != nullptr) {
      return ptr->QueryInterface(rclsid, (void **)pp);
    } else {
      return E_FAIL;
    }
  }
  HRESULT CoCreateInstance(REFCLSID clsid, IUnknown *pUnknown, REFIID interfaceId,
                           DWORD dwClsContext = CLSCTX_ALL) {
    HRESULT hr = ::CoCreateInstance(clsid, pUnknown, dwClsContext, interfaceId, (void **)&ptr);
    return hr;
  }
  ~comptr() {
    if (ptr != nullptr)
      ptr->Release();
  }

private:
  T *ptr{nullptr};
};

class comstr {
public:
  comstr() { str = nullptr; }
  comstr(const comstr &src) {
    if (src.str != nullptr) {
      str = ::SysAllocStringByteLen((char *)str, ::SysStringByteLen(str));
    } else {
      str = ::SysAllocStringByteLen(NULL, 0);
    }
  }
  comstr &operator=(const comstr &src) {
    if (str != src.str) {
      ::SysFreeString(str);
      if (src.str != nullptr) {
        str = ::SysAllocStringByteLen((char *)str, ::SysStringByteLen(str));
      } else {
        str = ::SysAllocStringByteLen(NULL, 0);
      }
    }
    return *this;
  }
  operator BSTR() const { return str; }
  BSTR *operator&() throw() { return &str; }
  ~comstr() throw() { ::SysFreeString(str); }

private:
  BSTR str;
};

} // namespace clangbuilder

#endif