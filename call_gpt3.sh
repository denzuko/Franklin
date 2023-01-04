#!/bin/bash
## Franklin is a gpt3 api calling bot for irc (easily adapted to other applications)


SITE="https://gpt3.oxasploits.com" # where to host the overrun
OUT_PTH="."
HARDL="-350"                       # hard limit (in bytes)
SOFTL="120"                        # soft limit (in words)
MODEL="text-davinci-003"
HEAT="0.7"
LOGF="./franklin.log"

SAY="$1"
WHO="$2"
WHO_S=$(echo ${WHO} | tr -d '`' | tr -d '&' | tr -d "'" | tr -d ";")
# I can't decide if you're wearing me out or wearing me well
# I just feel like I'm condemned to wear someone else's hell
# We've only reached the third day of our seven-day binge

function call_api () {
  APIKEY=$(<api.key)
  SRV="https://api.openai.com/v1/completions"
  if [[ $(grep "${WHO_S}" block.list | wc -l) -eq 0 ]]; then
    # some logging of user input
    echo "${WHO_S}: ${SAY}" >>${LOGF}
    # pull back json
    curl -s ${SRV} -H "Content-Type: application/json" -H "Authorization: Bearer ${APIKEY}" \
      -d "{\"model\": \"${MODEL}\",\"prompt\": \"${SAY}\",\"temperature\": ${HEAT},\"max_tokens\": \
      ${SOFTL},\"top_p\": 1,\"frequency_penalty\": 0,\"presence_penalty\": 0}" >res.txt
    # sanitizes input
    cat res.txt | tr -d "\'" | tr -d "\`" | tr -d "\;" | tr -d '\&' >sanitized.txt
    CALLR=$(md5sum < sanitized.txt | cut -c -8)
    # json extraction and formatting
    echo "${SAY}" >${OUT_PTH}/said/${CALLR}
    echo >>${OUT_PTH}/said/${CALLR}
    OUT_TXT=$(cat sanitized.txt | jq -r '.choices[].text' | sed -e 's|\\n||g' | tr -d '\n')
    echo "${OUT_TXT}" >>${OUT_PTH}/said/${CALLR}
    # add it to the webserver dir and say/log its response
    SAID=$(echo "${OUT_TXT}" | sed -e 's/[^\.]$/.../' | cut -c ${HARDL})
    echo "${SAID} ${SITE}/said/${CALLR}" | tee -a ${LOGF}
  else
    echo "You cannot use that command."
  fi
}

if [ -d ${OUT_PTH}/said ]; then
  call_api;
  rm sanitized.txt res.txt
else
  >&2 echo "Running setup routine..";
  mkdir -p ~/.irssi/scripts/ || die $?
  cp trigger.pl ~/.irssi/scripts/;
  mkdir -p ${OUT_PTH}/said || die $?
  touch ${LOGF}
  touch api.key
  >&2 echo "Setup complete..."
  call_api;
fi


