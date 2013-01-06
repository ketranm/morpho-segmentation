function blade_runner(params)
  println("warm up...")
  outfile = params.outfile
  params.outfile = strcat(outfile,"3.dict")
  #params.numit = 30
  #params.cluster = read_cluster(cluster_file)
  model_file = "models/pos_model"
  #params.state0 = load_model(model_file ,cluster_file)
  params.state0 = load_model(model_file)
  params.cluster = read_cluster(cluster_file)
  params.num_tags = 5
  params.init_seg = "state"
  params.init_stem = "state"
  state = run_gibbs(params)
  
  print("state 3")
  params.outfile = strcat(outfile,"2.dict")
  params.cluster = read_cluster(cluster_file)
  #println("live free or die hard...")
  params.state0 = state
  #params.numit = 50
  #state = run_gibbs(params)
end