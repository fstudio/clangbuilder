/*********************************************************************************************************
* Arguments.hpp
* Note: Phoenix CommandLine Arguments
* E-mail:<forcemz@outlook.com>
* Data: @2015.03
* Copyright (C) 2015 The ForceStudio All Rights Reserved.
**********************************************************************************************************/
#ifndef COMMANDLINEARGUMENTS_HPP
#define COMMANDLINEARGUMENTS_HPP
#pragma once
#include <string>
#include <vector>

class Arguments{
private:
    std::vector<wchar_t *> argv_;
public:
    static Arguments Main()
    {
        int ac;
        LPWSTR *w_av = CommandLineToArgvW(GetCommandLineW(), &ac);
        std::vector<std::wstring> av1(ac);
        std::vector<wchar_t const *> av2(ac);
        for (int i = 0; i < ac; i++) {
            av1[i]=w_av[i];
            av2[i] = av1[i].c_str();
        }
        LocalFree(w_av);
        return Arguments(ac,&av2[0]);
    }
    Arguments(int Argc,wchar_t const * const* Argv)
    {
        this->argv_.resize(Argc+1);
        for(int i=0;i<Argc;i++)
        {
            this->argv_[i]=_wcsdup(Argv[i]);
        }
        this->argv_[Argc]=0;
    }
    ~Arguments()
    {
        for(size_t i=0;i<this->argv_.size();i++){
            free(argv_[i]);
        }
    }
    int argc()const
    {
        return static_cast<int>(this->argv_.size() - 1);
    }
    wchar_t const* const* argv()const{
        return &this->argv_[0];
    }
};

#endif
