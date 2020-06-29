object global
{
	var a :boolean = false
	val b = 19

	def glo(): boolean
	{
		if(b>50)
			println("big")
		else
			println("small")
		
		if(b > 10)
			println("yesyssesyes")

		return a
	}
	def main ()
	{
		var bool:boolean
		bool = glo()
		println(bool)
	}
}

