using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class NewBehaviourScript : MonoBehaviour
{
    public GameObject cube;
    [SerializeField]
    private int amount=1;

    // Start is called before the first frame update
    // void OnEnable()
    // {
    //     for (int i = 0; i < amount; i++)
    //     {    
    //         GameObject obj=Instantiate<GameObject>(cube);
    //         obj.transform.SetPositionAndRotation(new Vector3(0,0,i*5),new Quaternion());
    //     }
    // }

    void Awake()
    {
        for (int i = 0; i < amount; i++)
        {    
            GameObject obj=Instantiate<GameObject>(cube);
            obj.transform.SetPositionAndRotation(new Vector3(0,0,i*5),new Quaternion());
        }
    }
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
