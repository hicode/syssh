<?php
class Classes_model extends Team_model{
	function __construct(){
		parent::__construct();
	}

	/**
	 * 根据学生id返回本学期所在班级的信息
	 * @param int $student_id
	 * @return array array(
	 *	num_in_class=>班中学号
	 *	num=>学号
	 *	class_name=>班级名称
	 *	class_teacher_name=>班主任姓名
	 * )
	 */
	function fetchByStudent($student_id){
		$student_id=intval($student_id);
		
		$this->db->select('
			people_team.id,people_team.name,team.leader,leader.name AS leader_name,
			people_relationship.num,
			CONCAT(RIGHT(10000+people_relationship.num,4),people_relationship.num) AS num
		',false)
			->from('people people_team')
			->join('team','people_team.id = team.id','inner')
			->join('people_relationship','people_relationship.people = people_team.id','inner')
			->join('people leader','leader.id = team.leader','left')
			->where('people_relationship.relative',$student_id)
			->where('people_relationship.till >= CURDATE()',NULL,FALSE);
		
		return $this->db->get()->row_array();
	}
	
}
?>