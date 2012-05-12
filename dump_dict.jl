function dump_dict(lexicon_state::LexiconState, dict_file)
  fh = open(dict_file,"w")
  for (w,ws) = lexicon_state.words
    write(fh, strcat(w,"\t",join(segments(ws)," - "),"\n"))
  end
  close(fh)
end
