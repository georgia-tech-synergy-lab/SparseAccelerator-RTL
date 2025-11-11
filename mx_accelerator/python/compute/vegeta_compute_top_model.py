def vegeta_compute_top_model(inputs, scale=1):
    """model of l1norm"""
    input_sum = sum(inputs)
    outputs = [(input_data * scale) / input_sum for input_data in inputs]
    return outputs
