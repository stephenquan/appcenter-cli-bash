#!/bin/bash -e

#----------------------------------------------------------------------

script_dir=$( cd $( dirname $0 ); pwd )

#----------------------------------------------------------------------

conf_file=~/.appcenter
stderr_file=/tmp/appcenter-cli-stderr.txt
stdout_file=/tmp/appcenter-cli-stdout.txt

#----------------------------------------------------------------------

debug=0
api_token=
owner_name=
app_name=
display_name=
distribution_group=
release_id=
app_id=
app_short_version=
app_version=
app_download_url=
app_size=
cmd=info

#----------------------------------------------------------------------

uname_s=$( uname -s )

#----------------------------------------------------------------------

if [ -f "${conf_file?}" ]; then
  . "${conf_file?}"
fi

#----------------------------------------------------------------------

show_syntax()
{
    cat <<EOF
Syntax: appcenter
                   -o owner_name
                   -X display_name
                   -D distribution_group
		   -d
		   -i release_id ( default 'latest' )
                   -t api_token
		   -c command ( default 'info' ) 
EOF
}

#----------------------------------------------------------------------

json_helper() {

    case "${uname_s?}" in

    MINGW*)
        cscript //nologo "${script_dir?}"/json-helper-win.js "$@"
        ;;

    *)
        python "${script_dir?}"/json-helper.py "$@"
        ;;

    esac
}

#----------------------------------------------------------------------

validate_owner_name() {
    if [ "${owner_name}" == "" ]; then
        cat <<EOF
Error: Missing -o owner_name.
EOF
        show_syntax
        exit 1
    fi
}

#----------------------------------------------------------------------

write_setting()
{
    local file=$1
    local key=$2
    local value=$3
    if [ "${file?}" == "" ]; then
      echo "Error: file is not set."
      exit 1
    fi
    if [ "${key?}" == "" ]; then
      echo "Error: file is not set."
      exit 1
    fi
    sed -i "${file?}" -e '/^'"${key?}"'=/d'
    echo "${key?}=${value?}" >> "${file?}"
}

#----------------------------------------------------------------------

write_config_setting()
{
    local key=$1
    local value=$2
    write_setting "${conf_file?}" "${key?}" "${value?}"
}

#----------------------------------------------------------------------

validate_display_name() {
    if [ "${display_name}" == "" ]; then
        cat <<EOF
Error: Missing -X display_name.
EOF
        show_syntax
        exit 1
    fi
}

#----------------------------------------------------------------------

validate_distribution_group() {
    if [ "${distribution_group}" == "" ]; then
        cat <<EOF
Error: Missing -D distribution_group.
EOF
        show_syntax
        exit 1
    fi
}

#----------------------------------------------------------------------

validate_app_name() {
    if [ "${app_name}" == "" ]; then
        cat <<EOF
Error: Cannot determine app_name. Please check -X display_name.
EOF
        show_syntax
        exit 1
    fi
}

#----------------------------------------------------------------------

validate_app_id() {
    if ! [[ "${app_id?}" =~ ^([0-9][0-9]*)$ ]]; then
        cat <<EOF
Error: Invalid app_id: ${app_id?}.
EOF
        show_syntax
	exit 1
    fi
}

#----------------------------------------------------------------------

validate_app_short_version() {
    if [ "${app_short_version}" == "" ]; then
        cat <<EOF
Error: Cannot determine app_short_version.
EOF
        exit 1
    fi
}

#----------------------------------------------------------------------

validate_app_version() {

    if [ "${app_version}" == "" ]; then
        cat <<EOF
Error: Cannot determine app_version.
EOF
        exit 1
    fi

}

#----------------------------------------------------------------------

validate_app_download_url() {

    if [ "${app_download_url}" == "" ]; then
        cat <<EOF
Error: Cannot determine app_download_url.
EOF
        exit 1
    fi

    if ! [[ "${app_download_url?}" =~ ^https://appcenter-.*\.azureedge\.net\/ ]]; then
        cat<<EOF
Warning: Download link no longer appears to be from appcenter.azureedge.net
EOF
    fi

}

#----------------------------------------------------------------------

validate_release_id() {
    if [ "${release_id}" == "" ]; then
        cat <<EOF
Error: Missing -i release_id.
EOF
        show_syntax
        exit 1
    fi
    if ! [[ "${release_id?}" =~ ^(latest|[0-9][0-9]*)$ ]]; then
        cat <<EOF
Error: Invalid release_id: ${release_id?}.
EOF
        show_syntax
	exit 1
    fi
}

#----------------------------------------------------------------------

validate_api_token() {
    if [ "${api_token}" == "" ]; then
        cat <<EOF
Error: Missing -t api_token.
EOF
        show_syntax
        exit 1
    fi
    if ! [[ "${api_token?}" =~ ^.{40}$ ]]; then
        cat <<EOF
Warning: Invalid -t api_token: ${api_token?}
EOF
        show_syntax
	# exit 1
    fi
}

#----------------------------------------------------------------------

validate_app_size() {
    if ! [[ "${app_size?}" =~ ^([0-9][0-9]*)$ ]]; then
        cat <<EOF
Error: Invalid app_size: ${app_size?}.
EOF
        show_syntax
	exit 1
    fi
}

#----------------------------------------------------------------------

appcenter_apps() {
    validate_api_token
    curl \
        -X GET \
        --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        --header 'X-API-Token: '${api_token?} \
        https://api.appcenter.ms/v0.1/apps \
	2> ${stderr_file?} \
	| json_helper \
	| tee ${stdout_file?}
}

#----------------------------------------------------------------------

find_app_name() {
    validate_display_name
    app_name=$( json_helper '[display_name='"${display_name}"']' name -raw < "${stdout_file}" )
    validate_app_name
}

#----------------------------------------------------------------------

find_app_id() {
    app_id=$( json_helper id < "${stdout_file?}" )
    validate_app_id
}

#----------------------------------------------------------------------

find_app_version() {
    app_version=$( json_helper version < "${stdout_file?}" )
    validate_app_version
}

#----------------------------------------------------------------------

find_app_short_version() {
    app_short_version=$( json_helper short_version -raw < "${stdout_file?}" )
    if [ "${app_short_version?}" == "" ]; then
        app_short_version="${app_version?}"
    fi
    validate_app_short_version

}

#----------------------------------------------------------------------

find_app_download_url() {
    app_download_url=$( json_helper download_url -raw < "${stdout_file?}" )
    validate_app_download_url
}

#----------------------------------------------------------------------

find_app_size() {
    app_size=$( json_helper size -raw < "${stdout_file?}" )
    validate_app_size
}

#----------------------------------------------------------------------

appcenter_info() {

    validate_api_token
    validate_owner_name
    validate_display_name
    validate_release_id

    appcenter_apps > /dev/null
    if (( debug )); then
        cat "${stdout_file?}"
    fi

    find_app_name

    if [ "${distribution_group}" != "" ]; then

        curl \
            -X GET \
            --header 'Content-Type: application/json' \
            --header 'Accept: application/json' \
            --header 'X-API-Token: '${api_token?} \
	    https://api.appcenter.ms/v0.1/apps/${owner_name?}/${app_name?}/distribution_groups/${distribution_group?}/releases/${release_id?} \
	    2> ${stderr_file?} \
	    | json_helper \
	    | tee ${stdout_file?}

    else

        curl \
            -X GET \
            --header 'Content-Type: application/json' \
            --header 'Accept: application/json' \
            --header 'X-API-Token: '${api_token?} \
            https://api.appcenter.ms/v0.1/apps/${owner_name?}/${app_name}/releases/${release_id?} \
	    2> ${stderr_file?} \
	    | json_helper \
	    | tee ${stdout_file?}

    fi

    find_app_id
    find_app_version
    find_app_short_version
    find_app_download_url
    find_app_size

}

#----------------------------------------------------------------------

appcenter_download_raw()
{

    local ext=${app_filename#*.}

    if [ -f "${app_filename?}" ]; then
        rm -rf "${app_filename?}"
    fi

    curl -L "${app_download_url?}" -o "${app_filename?}"

    local real_app_size=$( wc -c "${app_filename?}" | awk ' { print $1 } ' )

    if (( real_app_size < app_size )); then
        cat <<EOF
Error: ${app_filename?} is smaller than expected ${real_app_size?} < ${app_size?}
EOF
        rm "${app_filename?}"
        exit 1
    fi

}

#----------------------------------------------------------------------

appcenter_download_unzip()
{

    local ext=${app_filename#*.}

    if [ -f "${app_filename?}" ]; then
        rm -rf "${app_filename?}"
    fi

    if [ -f "${app_filename?}".zip ]; then
        rm -rf "${app_filename?}".zip
    fi

    if [ -f "${app_filename?}".dir ]; then
        rm -rf "${app_filename?}".dir
    fi

    curl -I "${app_download_url?}"
    curl -L "${app_download_url?}" -o "${app_filename?}".zip

    local real_app_size=$( wc -c "${app_filename?}".zip | awk ' { print $1 } ' )

    if (( real_app_size < app_size )); then
        cat <<EOF
Error: ${app_filename?} is smaller than expected ${real_app_size?} < ${app_size?}
EOF
        rm "${app_filename?}"
        exit 1
    fi

    if [ -d "${app_filename?}".dir ]; then
      rm -rf -d "${app_filename?}".dir
    fi

    mkdir "${app_filename?}".dir
    ( cd "${app_filename?}".dir; unzip ../"${app_filename?}".zip )

    local filename=$( cd "${app_filename?}".dir; find . -maxdepth 1 -iname '*.'${ext} )
    if [ "${filename?}" == "" ]; then
        cat <<EOF
Error: Cannot locate filename in archive.
EOF
        rm -rf "${app_filename?}".dir
	return
    fi

    mv "${app_filename?}".dir/"${filename?}" "${app_filename?}"
    rm -rf "${app_filename?}".dir
    rm -rf "${app_filename?}".zip

}

#----------------------------------------------------------------------

appcenter_download()
{

    appcenter_info

    curl -I "${app_download_url?}" \
	2> ${stderr_file?} \
	| tee ${stdout_file?}

    local suffix=_"${app_short_version//./_}"_"${app_id?}"

    case "${display_name}" in
    *.*)
        app_filename=${display_name/./${suffix}.}
	;;
    *)
        app_filename=${display_name?}${suffix}.zip
	;;
    esac

    content_type=$(
            grep '^Content-Type: ' "${stdout_file?}" \
	    | head -1 \
	    | perl -pe 's/^Content-Type: (.*)/\1/' )

    case "${app_filename?}" in

    *.exe)
        appcenter_download_unzip
	;;

    *)
        appcenter_download_raw
	;;

    esac

}

#----------------------------------------------------------------------

while getopts ":X:i:o:dD:t:c:" opt; do

    case ${opt?} in

    o)
        owner_name=${OPTARG?}
	validate_owner_name
	write_config_setting owner_name "${owner_name?}"
	;;

    X)
        display_name=${OPTARG?}
	validate_display_name
	write_config_setting display_name "${display_name?}"
	;;

    i)
        release_id=${OPTARG?}
	validate_release_id
	write_config_setting release_id "${release_id?}"
	;;

    d)
        debug=1
        set -x
	;;

    D)
        distribution_group=${OPTARG?}
	# validate_distribution_group
	write_config_setting distribution_group "${distribution_group?}"
	;;

    t)
        api_token=${OPTARG?}
	validate_api_token
	write_config_setting api_token "${api_token?}"
	;;

    c)
        cmd=${OPTARG?}
        ;;
    esac

done

#----------------------------------------------------------------------

case "${cmd?}" in

apps)
    appcenter_apps
    ;;

info)
    appcenter_info
    ;;

download)
    appcenter_download
    ;;

*)
    cat <<EOF
Error: Unknown command: -c ${cmd?}.
EOF
    show_syntax
    exit 1

esac

