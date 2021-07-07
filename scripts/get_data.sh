#!/bin/bash

# - This is written to execute on WSL2 Ubuntu 20.04.
# - The use case is tracking data for COVID19.
# - Depends on gnuplot to create chart

workdir='D:\Madhukar\covid19india'
wslwdir="$(wslpath "${workdir}")"
logsdir="${wslwdir}/log"
infile="${wslwdir}/urls.txt"
dtfile='case_time_series.csv'
dir=$(date +%Y-%m-%d)
datadir="${workdir}\\${dir}"
wslddir="$(wslpath "${datadir}")"
execlog="${logsdir}/get-data-${dir}.log"

# --------------------------------------------------------------------

function get_data {
    local urls=${1}
    if [[ -e ${urls} ]]
    then
	if [[ ! -e ${dir} ]]
	then
	    mkdir ${dir}
	else
	    explorer.exe "${datadir}"
	    echo "[info] Directory exists: ${datadir}"
	    exit 0
	fi
	pushd ${dir} > /dev/null
        wget -i ${urls}
	popd  > /dev/null
    else
        echo "[Error] Could not open the file with URLs - ${urls}"
        return 1
    fi

    echo "[info] Downloaded today's data, placed it in: ${datadir}"
    return 0
}

# --------------------------------------------------------------------

function plot_data {
    local datfile=${1}
    local outfile="${dir}/COVID19-Cases.jpg"

    # Set titles of the curves
    local title_mn='India COVID-19 Case Data'
    local title_p1=$(head -1 ${datfile} | awk -F ',' '{print $3}')
    local title_p2=$(head -1 ${datfile} | awk -F ',' '{print $5}')
    local title_p3=$(head -1 ${datfile} | awk -F ',' '{print $8}')

    # Get the X Axis range as per available data
    local x_beg=$(head -2 ${datfile} | tail -1 | awk -F ',' '{print $2}')
    local x_end=$(tail -1 ${datfile} | awk -F ',' '{print $2}')

    # Get the Y Axis range as per available data
    local y_beg=0
    local y_end1=$(grep -v 'Date' ${datfile} | awk -F ',' '{print $3}' | sort -n | tail -1)
    local y_end2=$(grep -v 'Date' ${datfile} | awk -F ',' '{print $3}' | sort -n | tail -1)
    local y_end3=$(grep -v 'Date' ${datfile} | awk -F ',' '{print $3}' | sort -n | tail -1)
    local y_end=$(printf "${y_end1}\n${y_end2}\n${y_end3}\n" | sort -n | tail -1)
    
    # Plot downloaded data with GNUPlot
    gnuplot <<EOF
    set xdata time
    set timefmt "%Y-%m-%d"
    set format x "%Y/%m/%d"
    set datafile sep ','

    set xrange ["${x_beg}":"${x_end}"]	
    set yrange [${y_beg}:${y_end}]

    set key left top
    set xtics rotate by -45
    set title "${title_mn}" font ",18"
    set grid

    set terminal jpeg size 1500,650
    set output "${outfile}"

    plot "${datfile}" using 2:3 with lines linetype 6 linewidth 1 title "${title_p1}", \
         "${datfile}" using 2:5 with lines linetype 7 linewidth 1 title "${title_p2}", \
         "${datfile}" using 2:8 with lines linetype 2 linewidth 1 title "${title_p3}"
EOF
    return 0
}

# --------------------------------------------------------------------

function main {
    get_data ${infile} 2> ${execlog}
    if [[ $? -eq 0 ]] && [[ -e ${wslddir}/${dtfile} ]]
    then
        plot_data ${wslddir}/${dtfile}
	explorer.exe "${datadir}"
    else
        echo "[Error] Could not find - ${wslddir}/${dtfile}"
        exit 1
    fi
    return
}

# --------------------------------------------------------------------
main
