//////////////
#define NOMINMAX
#include "stdafx.h"
#include <stdio.h>
#include <shellapi.h>
#include <Shlwapi.h>
#include <PathCch.h>
#include <strsafe.h>
#include <sstream>
#include <fstream>
#include <unordered_map>
#include "Clangbuilder.h"
#include "cmVSSetupHelper.h"
#include "json.hpp"

bool PutEnvironmentVariableW(const wchar_t *name, const wchar_t *va)
{
	std::wstring buf(PATHCCH_MAX_CCH, L'\0');
	auto buffer = &buf[0];
	auto dwSize = GetEnvironmentVariableW(name, buffer, PATHCCH_MAX_CCH);
	if (dwSize <= 0)
	{
		return SetEnvironmentVariableW(name, va) ? true : false;
	}
	if (dwSize >= PATHCCH_MAX_CCH)
		return false;
	if (buffer[dwSize - 1] != ';')
	{
		buffer[dwSize] = ';';
		dwSize++;
		buffer[dwSize] = 0;
	}
	StringCchCatW(buffer, PATHCCH_MAX_CCH - dwSize, va);
	return SetEnvironmentVariableW(name, buffer) ? true : false;
}

/// HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\SxS\VS7 11.0
/// 12.0 14.0

#if defined(_M_X64)
#define VSREG_KEY L"SOFTWARE\\WOW6432Node\\Microsoft\\VisualStudio\\SxS\\VS7"
#else
#define VSREG_KEY L"SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7"
#endif

bool VisualStudioExists(const std::wstring &id)
{
	HKEY hInst = nullptr;
	if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, VSREG_KEY, 0, KEY_READ, &hInst) !=
		ERROR_SUCCESS)
	{
		/// Not Found Key
		return false;
	}
	DWORD type = REG_SZ;
	WCHAR buffer[4096];
	DWORD dwSize = sizeof(buffer);
	if (RegGetValueW(hInst, nullptr, id.data(), RRF_RT_REG_SZ, &type, buffer,
					 &dwSize) != ERROR_SUCCESS)
	{
		RegCloseKey(hInst);
		return false;
	}
	RegCloseKey(hInst);
	return true;
}

static uint16_t ByteSwap(uint16_t i)
{
	uint16_t j;
	j = (i << 8);
	j += (i >> 8);
	return j;
}

static inline void ByteSwapShortBuffer(WCHAR *buffer, int len)
{
	int i;
	uint16_t *sb = reinterpret_cast<uint16_t *>(buffer);
	for (i = 0; i < len; i++)
	{
		sb[i] = ByteSwap(sb[i]);
	}
}

std::wstring utf8towide(const char *str, DWORD len)
{
	std::wstring wstr;
	auto N =
		MultiByteToWideChar(CP_UTF8, 0, str, len, nullptr, 0);
	if (N > 0)
	{
		wstr.resize(N);
		MultiByteToWideChar(CP_UTF8, 0, str, len, &wstr[0], N);
	}
	return wstr;
}

bool VisualCppToolsSearch(const std::wstring &cbroot, std::wstring &version)
{
	std::wstring file = cbroot + L"\\utils\\msvc\\VisualCppTools.lock.txt";
	HANDLE hFile = CreateFileW(file.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL,
							   OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	if (hFile == INVALID_HANDLE_VALUE)
	{
		return false;
	}
	UINT8 buf[2050] = {0};
	DWORD dwRead = 0;
	if (!ReadFile(hFile, buf, 2048, &dwRead, nullptr))
	{
		CloseHandle(hFile);
		return false;
	}
	if (dwRead == 0)
	{
		CloseHandle(hFile);
		return false;
	}
	if (buf[0] == 0xFF && buf[1] == 0xFE)
	{
		auto iter = reinterpret_cast<wchar_t *>(buf + 2);
		version.assign(iter, (dwRead - 2) / 2);
	}
	else if (buf[0] == 0xFE && buf[1] == 0xFF)
	{
		auto iter = reinterpret_cast<wchar_t *>(buf + 2);
		ByteSwapShortBuffer(iter, (dwRead - 2) / sizeof(wchar_t));
		version.assign(iter, (dwRead - 2) / 2);
	}
	else
	{
		auto iter = buf;
		if (buf[0] == 0xEF && buf[1] == 0xBB &&
			buf[2] == 0xBF)
		{
			iter += 3;
			dwRead = dwRead - 3;
		}
		version = utf8towide(reinterpret_cast<char *>(iter), dwRead);
	}
	auto n = version.find(L"\r");
	if (n != version.npos)
	{
		version.resize(n);
	}
	n = version.find(L"\n");
	if (n != version.npos)
	{
		version.resize(n);
	}
	CloseHandle(hFile);
	return true;
}

bool EnterpriseWDKSensor(const std::wstring &cbroot, VisualStudioInstance &inst)
{
	try
	{
		std::wstring file = cbroot + L"\\config\\ewdk.json";
		std::ifstream fs;
		fs.open(file, std::ios::binary);
		auto j = nlohmann::json::parse(fs);
		auto path = j["Path"].get<std::string>();
		auto version = j["Version"].get<std::string>();
		auto wpath = utf8towide(path.c_str(), (DWORD)path.size());
		if (!PathFileExistsW(wpath.c_str()))
		{
			return false;
		}
		auto wversion = utf8towide(version.c_str(), (DWORD)version.size());
		inst.description.assign(L"Enterprise WDK ").append(wversion);
		inst.installversion.assign(wversion);
		inst.instanceId.assign(L"VisualStudio.EWDK");
	}
	catch (const std::exception &e)
	{
		fprintf(stderr, "%s\n", e.what());
		return false;
	}
	return true;
}

bool VisualStudioSearch(const std::wstring &cbroot, std::vector<VisualStudioInstance> &instances)
{
	//instances.clear();
	std::vector<VisualStudioInstance> vss = {
		{L"Visual Studio 2010", L"10.0", L"VisualStudio.10.0"},
		{L"Visual Studio 2012", L"11.0", L"VisualStudio.11.0"},
		{L"Visual Studio 2013", L"12.0", L"VisualStudio.12.0"},
		{L"Visual Studio 2015", L"14.0", L"VisualStudio.14.0"}
		/// legacy VisualStudio
	};
	for (auto &vs : vss)
	{
		if (VisualStudioExists(vs.installversion))
		{
			instances.emplace_back(vs);
		}
	}
	VisualStudioInstance inst;
	if (EnterpriseWDKSensor(cbroot, inst))
	{
		instances.push_back(std::move(inst));
	}
	std::wstring version;
	if (VisualCppToolsSearch(cbroot, version))
	{
		VisualStudioInstance vs;
		vs.description.assign(version);
		vs.instanceId.assign(L"VisualCppTools");
		vs.installversion.assign(L"15.0");
		instances.push_back(std::move(vs));
	}
	cmVSSetupAPIHelper helper;
	std::vector<VSInstanceInfo> vsInstances;
	if (helper.GetVSInstanceInfo(vsInstances))
	{
		for (auto &vs : vsInstances)
		{
			instances.emplace_back(vs.DisplayName, vs.Version, vs.InstanceId);
		}
	}
	return true;
}
