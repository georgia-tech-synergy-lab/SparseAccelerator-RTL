foreach M (4 8 16 32 64)
    foreach K (4 8 16 32 64)
        foreach N (4 8 16 32 64)
            foreach ALPHA (2) #1 2 4 8 16 32 64)
                if ($ALPHA <= $M) then
                    sed -i 's/    localparam M = [0-9]*\;/    localparam M = '"${M}"'\;/g' vegeta_top_tb.sv
                    sed -i 's/    localparam K = [0-9]*\;/    localparam K = '"${K}"'\;/g' vegeta_top_tb.sv
                    sed -i 's/    localparam N = [0-9]*\;/    localparam N = '"${N}"'\;/g' vegeta_top_tb.sv
                    sed -i 's/    localparam ALPHA = [0-9]*\;/    localparam ALPHA = '"${ALPHA}"'\;/g'vegeta_top_tb.sv
                    make vcs > /dev/null
                    setenv result `tac vegeta_top_tb.log | head -n 8 | tail -n 1`
                    echo "${M} ${K} ${N} ${ALPHA}: ${result}"
                endif
            end
        end
    end
end