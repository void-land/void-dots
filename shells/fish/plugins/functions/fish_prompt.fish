function fish_prompt --description Hydro
    echo -e "$_hydro_color_pwd$(prompt_login) $_hydro_pwd$hydro_color_normal $_hydro_color_git$$_hydro_git$hydro_color_normal$_hydro_color_duration$_hydro_cmd_duration$hydro_color_normal$_hydro_status$hydro_color_normal "
end
