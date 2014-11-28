class String
  def float?
    !!Float(self) rescue false
  end

  def integer?
    !!Integer(self) rescue false
  end
end
